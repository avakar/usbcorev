import sys

while True:
    crc = 0xffff

    binary = raw_input('Enter sequence: ')
    for ch in binary:
        top = (crc & 0x8000) != 0
        crc = (crc << 1) & 0xffff
        if (ch == '1') != top:
            crc = crc ^ 0x8005

    print bin(crc)
