# Stock firmware for Xiaomi Mi4C router
The file were extracted from `miwifi_r4cm_firmware_82790_3.0.16_INT.bin`

# Firmware content
```bash
$ binwalk miwifi_r4cm_firmware_82790_3.0.16_INT.bin

-----------------------------------------------------------------------------------------------------------------------
DECIMAL                            HEXADECIMAL                        DESCRIPTION
-----------------------------------------------------------------------------------------------------------------------
676                                0x2A4                              uImage firmware image, header size: 64 bytes, 
                                                                      data size: 1454427 bytes, compression: lzma, 
                                                                      CPU: MIPS32, OS: Linux, image type: OS Kernel 
                                                                      Image, load address: 0x80000000, entry point: 
                                                                      0x80000000, creation time: 2020-02-18 07:14:29, 
                                                                      image name: "MIPS OpenWrt Linux-3.10.14"
1508004                            0x1702A4                           SquashFS file system, little endian, version: 
                                                                      4.0, compression: xz, inode count: 2126, block 
                                                                      size: 262144, image size: 8556406 bytes, 
                                                                      created: 2020-02-18 07:14:23

```

# Getting rootfs
```bash
dd if=miwifi_r4cm_firmware_82790_3.0.16_INT.bin of=rootfs.sqfs bs=1 skip=1508004
```

# Extracting rootfs
```bash
unsquashfs rootfs.sqfs
```
