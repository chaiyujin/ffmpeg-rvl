import os
import shutil
import argparse


def get_args():
    parser = argparse.ArgumentParser("Install RVL depth compression lib to ffmpeg 3.4")
    parser.add_argument("root", type=str, help="FFMpeg root dir.")
    args = parser.parse_args()
    return args


def check_exist(lines, to_write):
    i = 0
    while i < len(lines):
        j = 0
        while i < len(lines) and j < len(to_write):
            if lines[i].strip() == to_write[j].strip():
                i += 1
                j += 1
            else:
                break
        if j == len(to_write):
            return True
        i += 1
    return False


def append_makefile(filename, after_line, offset, to_write):
    if not isinstance(to_write, (list, tuple)):
        to_write = [to_write]
    with open(filename) as fin:
        lines = fin.readlines()
    if check_exist(lines, to_write):
        print("already patch to {}".format(filename))
        return
    index = -1
    for i, line in enumerate(lines):
        if line.strip().find(after_line.strip()) >= 0:
            index = i
            break
    assert index >= 0
    index += offset
    with open(filename, "w") as fout:
        for i, line in enumerate(lines):
            fout.write(line)
            if i == index:
                for new_line in to_write:
                    fout.write(new_line + "\n")


def append_source(filename, block_start, to_write, at_start=False):
    if not isinstance(to_write, (list, tuple)):
        to_write = [to_write]
    with open(filename) as fin:
        lines = fin.readlines()
    if check_exist(lines, to_write):
        print("already patch to {}".format(filename))
        return

    index = -1
    block_start = block_start.strip()
    for i, line in enumerate(lines):
        if index == -1:
            if line.strip().find(block_start) >= 0:
                index = i
                if at_start and line.strip().find("{") >= 0:
                    break
        else:
            if at_start == False:
                if line.strip().find("}") >= 0:
                    index = i - 1
                    break
            else:
                if line.strip().find("{") >= 0:
                    index = i
                    break
    with open(filename, "w") as fout:
        for i, line in enumerate(lines):
            fout.write(line)
            if i == index:
                for new_line in to_write:
                    fout.write(new_line + "\n")


def install_avcodec(source, target):
    # copy files
    def copyfile(filename):
        shutil.copyfile(os.path.join(source, filename),
                        os.path.join(target, filename))
    copyfile("librvldepth.h")
    copyfile("librvldepth.c")
    copyfile("librvldepthenc.c")
    copyfile("librvldepthdec.c")

    # change file
    append_source(
        os.path.join(target, "allcodecs.c"),
        "static void register_all(void)",
        to_write="    REGISTER_ENCDEC (LIBRVLDEPTH,       librvldepth);")
    append_source(
        os.path.join(target, "avcodec.h"),
        "enum AVCodecID",
        to_write="    AV_CODEC_ID_RVLDEPTH,")
    append_source(
        os.path.join(target, "codec_desc.c"),
        "static const AVCodecDescriptor codec_descriptors[]",
        to_write=[
            "    {",
            "        .id        = AV_CODEC_ID_RVLDEPTH,",
            "        .type      = AVMEDIA_TYPE_VIDEO,",
            "        .name      = \"rvldepth\",",
            "        .long_name = NULL_IF_CONFIG_SMALL(\"RVL Depth Stream\"),",
            "        .props     = AV_CODEC_PROP_LOSSLESS",
            "    },"
        ],
        at_start=True
    )
    # makefile
    append_makefile(
        os.path.join(target, "Makefile"),
        after_line="OBJS-$(CONFIG_LIBOPENH264_ENCODER)", offset=0,
        to_write=[
            "OBJS-$(CONFIG_LIBRVLDEPTH_DECODER)        += librvldepthdec.o librvldepth.o",
            "OBJS-$(CONFIG_LIBRVLDEPTH_ENCODER)        += librvldepthenc.o librvldepth.o"
        ])


def install_avformat(target):
    append_source(
        os.path.join(target, "matroska.c"),
        "const CodecTags ff_mkv_codec_tags[]",
        to_write="    {\"V_DEPTH\"       , AV_CODEC_ID_RVLDEPTH},",
        at_start=True)
    append_source(
        os.path.join(target, "matroskaenc.c"),
        "static const AVCodecTag additional_video_tags[]",
        to_write="    { AV_CODEC_ID_RVLDEPTH,  0xFFFFFFFF },",
        at_start=True)


def install():
    args = get_args()
    assert os.path.exists(args.root), "`{}` does not exist.".format(args.root)
    # check directories and files are there
    libavcodec_path = os.path.join(args.root, "libavcodec")
    libavformat_path = os.path.join(args.root, "libavformat")
    # check avcodec
    assert os.path.exists(os.path.join(libavcodec_path, "Makefile"))
    assert os.path.exists(os.path.join(libavcodec_path, "allcodecs.c"))
    assert os.path.exists(os.path.join(libavcodec_path, "avcodec.h"))
    assert os.path.exists(os.path.join(libavcodec_path, "codec_desc.c"))
    # check avformat
    assert os.path.exists(os.path.join(libavformat_path, "matroska.c"))
    assert os.path.exists(os.path.join(libavformat_path, "matroska.h"))
    assert os.path.exists(os.path.join(libavformat_path, "matroskadec.c"))
    assert os.path.exists(os.path.join(libavformat_path, "matroskaenc.c"))
    
    install_avcodec("./libavcodec", libavcodec_path)
    install_avformat(libavformat_path)


if __name__ == "__main__":
    install()
