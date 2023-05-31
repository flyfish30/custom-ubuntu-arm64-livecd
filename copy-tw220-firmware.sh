#! /bin/bash

RELEASE=${1:-lunar}
WORK_DIR=$HOME/$RELEASE-custom

# copy firmware of Qualcomm soc for Ntmer TW220 product
LIB_FIRMWARE_DIR=$WORK_DIR/chroot/usr/lib/firmware
QCOM_FIRMWARE_DIR=$LIB_FIRMWARE_DIR/qcom
TW220_FIRMWARE_DIR=$QCOM_FIRMWARE_DIR/sc8280xp/Ntmer/TW220
mkdir -p $TW220_FIRMWARE_DIR
mkdir -p $QCOM_FIRMWARE_DIR/Ntmer

if [ ! -L $QCOM_FIRMWARE_DIR/Ntmer/TW220 ]
then
	ln -s ../sc8280xp/Ntmer/TW220 $QCOM_FIRMWARE_DIR/Ntmer/TW220
fi
cp $PWD/tw220-firmware/sc8280xp/* $TW220_FIRMWARE_DIR/
cp $PWD/tw220-firmware/qcom/* $QCOM_FIRMWARE_DIR/
cp $PWD/tw220-firmware/ath11k/WCN6855/hw2.0/* $LIB_FIRMWARE_DIR/ath11k/WCN6855/hw2.0/


