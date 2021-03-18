#!/bin/bash

# 该脚本用于自动构建内核调试环境
#
# author: sebastian

get_cmd()
{
    cmd_name=$1
    
    cmd=`which $cmd_name`
    if [ $? -ne 0 ];then
        echo ""
    fi
    
    echo $cmd
}

mk_initramfs()
{
    bin=$(get_cmd "mkinitramfs")
    
    if [ x"" == x"$bin" ];then
        bin=$(get_cmd "mkinitrd")
        if [ x"" == x"$bin" ];then
            echo "Please install mkinitramfs or mkinitrd"
            exit 1
        fi
    fi
    
    if [ "$bin"=~"mkinitramfs" ];then
        param="-o ramdisk.img"
    else
        #Todo 添加mkinitrd构建参数
        param=""
    fi

    $bin $param
    if [ $? -ne 0 ];then
        echo "Failed to create file ramdisk.img"
        exit 1
    fi
}

mk_kernel()
{
    source_path=$1

    if [ x"" == x"$source_path" ];then
        echo "Please set kernel source code path"
        exit 1
    fi     

    cd "$source_path"
    grep -rn "CONFIG_DEBUG_INFO=y" ".config" > /dev/null
    if [ $? -ne 0 ];then
        echo "Please modify .config, add CONFIG_DEBUG_INFO=y"
        exit 1
    fi

    make -j8 
}

start_qemu()
{
    kernel_path=$1
    if [ x"" == x"$kernel_path" ];then
        echo "Please set kernel source code path"
        exit 1
    fi

    #Todo arm下不同的命令名字
    cmd=$(get_cmd "qemu-system-x86_64")
    if [ x"" == x"$cmd" ];then
        echo "qemu-system-x86_64 is not exist, please install qemu"
        exit 1
    fi

    params="-kernel $kernel_path/arch/x86_64/boot/bzImage 
            -nographic 
            -append \"console=ttyS0,nokaslr\" 
            -initrd ramdisk.img 
            -m 1024 
            --enable-kvm 
            -cpu host 
            -s -S" 
    
    $cmd $params &
    if [ $? -ne 0 ];then
        echo "Failed to start virtual machine"
    else
        echo "virtual machine start success, please run \"gdb vmlinux\" to start debug kernel"
    fi
}

# Step 1:创建initramfs文件
mk_initramfs

# Step 2:编译内核
mk_kernel $1

# Step 3:启动qemu虚拟机
start_qemu $1