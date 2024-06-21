# Stock firmware for Xiaomi Mi4C router
The file were extracted from `miwifi_r4cm_firmware_c6fa8_3.0.23_INT.bin`

# Firmware content
```bash
$ binwalk miwifi_r4cm_firmware_c6fa8_3.0.23_INT.bin

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
676           0x2A4           uImage header, header size: 64 bytes, header CRC: 0x997EE441, created: 2020-08-14 12:36:07, image size: 1436818 bytes, Data Address: 0x80000000, Entry Point: 0x80000000, data CRC: 0x928A9589, OS: Linux, CPU: MIPS, image type: OS Kernel Image, compression type: lzma, image name: "MIPS OpenWrt Linux-3.10.14"
740           0x2E4           LZMA compressed data, properties: 0x6D, dictionary size: 8388608 bytes, uncompressed size: 4158860 bytes
1442468       0x1602A4        Squashfs filesystem, little endian, version 4.0, compression:xz, size: 9022674 bytes, 2173 inodes, blocksize: 262144 bytes, created: 2020-08-14 12:36:01
```

# Getting rootfs
```bash
dd if=miwifi_r4cm_firmware_c6fa8_3.0.23_INT.bin of=rootfs.sqfs bs=1 skip=1442468
```

# Extracting rootfs
```bash
unsquashfs rootfs.sqfs
```
