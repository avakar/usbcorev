import sys

while True:
    crc = 0x1f

    binary = raw_input('Enter sequence: ')
    for ch in binary:
        top = (crc & 0x10) != 0
        crc = (crc << 1) & 0x1f
        if (ch == '1') != top:
            crc = crc ^ 5

    print bin(crc)
