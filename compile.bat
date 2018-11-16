nasm -f bin -o build/kernel src/kernel.asm
nasm -f bin -o build/boot src/boot.asm
mkfloppy build/bootdisk.img build/boot build/kernel