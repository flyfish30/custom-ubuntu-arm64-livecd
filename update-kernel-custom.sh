#! /bin/bash
set -x

KERNEL=${1}

if [ -z $KERNEL ]
then
    printf "Please specify a kernel package (deb) as the first parameter."
    exit
fi

# Set the Ubuntu release here
RELEASE=${2:-kinetic}

WORK_DIR=$HOME/$RELEASE-custom

mkdir $WORK_DIR

mount --bind /dev $WORK_DIR/chroot/dev
mount --bind /run $WORK_DIR/chroot/run

# Copy kernel with support for new hardware
# e.g.
cp $KERNEL $WORK_DIR/chroot/

# Copy chroot.sh for update kernel
cp $PWD/update-kernel-chroot.sh $WORK_DIR/chroot/

# setup the live environment under chroot
chroot $WORK_DIR/chroot /bin/bash -c "RELEASE=$RELEASE ./update-kernel-chroot.sh"

# unmount dev/run
umount $WORK_DIR/chroot/run
umount $WORK_DIR/chroot/dev

mkdir -p $WORK_DIR/image/{casper,isolinux,install}

# copy kernel from chroot
cp $WORK_DIR/chroot/boot/vmlinuz-* $WORK_DIR/image/casper/vmlinuz
cp $WORK_DIR/chroot/boot/initrd.img-* $WORK_DIR/image/casper/initrd

# create package manifest
chroot $WORK_DIR/chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee $WORK_DIR/image/casper/filesystem.manifest
cp -v $WORK_DIR/image/casper/filesystem.manifest $WORK_DIR/image/casper/filesystem.manifest-desktop
sed -i '/ubiquity/d' $WORK_DIR/image/casper/filesystem.manifest-desktop
sed -i '/casper/d' $WORK_DIR/image/casper/filesystem.manifest-desktop
sed -i '/discover/d' $WORK_DIR/image/casper/filesystem.manifest-desktop
sed -i '/laptop-detect/d' $WORK_DIR/image/casper/filesystem.manifest-desktop
sed -i '/os-prober/d' $WORK_DIR/image/casper/filesystem.manifest-desktop

# create live filesystem
mksquashfs $WORK_DIR/chroot $WORK_DIR/image/casper/filesystem.squashfs
printf $(sudo du -sx --block-size=1 $WORK_DIR/chroot | cut -f1) > $WORK_DIR/image/casper/filesystem.size

# create diskdefines
cat <<EOF > $WORK_DIR/image/README.diskdefines
#define DISKNAME  Ubuntu arm64 custom
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  arm64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF

# create standalone grub binary
(
    cd $WORK_DIR/image/ &&
    grub-mkstandalone \
    --format=arm64-efi \
    --output=isolinux/grubaa64.efi \
    --directory=../chroot/grub-arm64-efi \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=isolinux/grub.cfg"
)

# copy needed device trees installed with kernel
mkdir $WORK_DIR/image/isolinux/dtb
#cp $WORK_DIR/chroot/usr/lib/linux-image-*/apple/*.dtb $WORK_DIR/image/isolinux/dtb
#cp $WORK_DIR/chroot/usr/lib/linux-image-*/apple/*.dtb $WORK_DIR/image/isolinux/dtb
#cp $WORK_DIR/chroot/usr/lib/linux-image-*/apple/*.dtb $WORK_DIR/image/isolinux/dtb
cp $WORK_DIR/chroot/usr/lib/linux-image-*/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb $WORK_DIR/image/isolinux/dtb/f249803d-0d95-54f3-a28f-f26c14a03f3b.dtb
cp $WORK_DIR/chroot/usr/lib/linux-image-*/qcom/sc8280xp-ntm-tw220.dtb $WORK_DIR/image/isolinux/dtb/0d0a41c6-ac69-512a-8d36-96ca6d84aee1.dtb

# copy kernel
cp $WORK_DIR/chroot/boot/vmlinuz-* $WORK_DIR/image/casper/vmlinuz
cp $WORK_DIR/chroot/boot/initrd.img-* $WORK_DIR/image/casper/initrd

# create efi system partition
(
    cd $WORK_DIR/image/isolinux && \
    dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
    sudo mkfs.vfat efiboot.img && \
    LC_CTYPE=C mmd -i efiboot.img dtb efi efi/boot && \
    LC_CTYPE=C mcopy -i efiboot.img ./dtb/f249803d-0d95-54f3-a28f-f26c14a03f3b.dtb ::dtb/ && \
    LC_CTYPE=C mcopy -i efiboot.img ./dtb/0d0a41c6-ac69-512a-8d36-96ca6d84aee1.dtb ::dtb/ && \
    LC_CTYPE=C mcopy -i efiboot.img ./grubaa64.efi ::efi/boot/ && \
    LC_CTYPE=C mcopy -i efiboot.img ./bootaa64.efi ::efi/boot/
)

# create md5sum
(
    cd $WORK_DIR/image &&
    /bin/bash -c "(find . -type f -print0 | xargs -0 md5sum | grep -v -e 'md5sum.txt' -e 'efiboot.img' > md5sum.txt)"
)

# create iso image
(
    cd $WORK_DIR/image &&
    xorriso \
        -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "Ubuntu arm64 custom" \
        -output "../ubuntu-$RELEASE-arm64-custom.iso" \
        -eltorito-alt-boot \
            -e EFI/efiboot.img \
            -no-emul-boot \
        -append_partition 2 0xef isolinux/efiboot.img \
        -m "isolinux/efiboot.img" \
        -graft-points \
            "/EFI/efiboot.img=isolinux/efiboot.img" \
            "."
)
