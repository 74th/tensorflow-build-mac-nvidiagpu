#!/bin/bash
set -Cex
if [ "${TENSORFLOW_VER}" == "" ];then
    TENSORFLOW_VER=v1.9.0
fi
if [ "${PYTHON_ENV_VER}" == "" ];then
    # brew install pyenv-virtualenv
    # pyenv virtualenv 3.6.5 3.6.5-cuda
    PYENV_VERSION=3.6.5-cuda
fi

eval "$(pyenv init -)"
pyenv shell ${PYENV_VERSION}

# see https://www.tensorflow.org/install/install_sources
#pip install six numpy wheel 

cd tensorflow/
#git fetch
#git checkout ${TENSORFLOW_VER}

if [ "${CUDA_HOME}" == "" ];then
    export CUDA_HOME="/usr/local/cuda"
fi
export DYLD_LIBRARY_PATH=${CUDA_HOME}/lib:${CUDA_HOME}/extras/CUPTI/lib
export LD_LIBRARY_PATH=$DYLD_LIBRARY_PATH
export PATH=$DYLD_LIBRARY_PATH:$PATH


# see https://github.com/tensorflow/tensorflow/blob/master/configure.py
export PYTHON_BIN_PATH=$(which python)
export PYTHON_LIB_PATH="$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')"
export TF_NEED_S3=1
export TF_NEED_GCP=1
export TF_NEED_HDFS=1
export TF_NEED_JEMALLOC=1

export TF_NEED_CUDA=1

if [ "${TF_CUDA_VERSION}" == "" ];then
    export TF_CUDA_VERSION="9.2"
fi
if [ "${CUDA_TOOLKIT_PATH}" == "" ];then
    export CUDA_TOOLKIT_PATH="/usr/local/cuda"
fi
if [ "${TF_CUDNN_VERSION}" == "" ];then
    export TF_CUDNN_VERSION=7
fi
if [ "${CUDNN_INSTALL_PATH}" == "" ];then
    export CUDNN_INSTALL_PATH=${CUDA_TOOLKIT_PATH}
fi
if [ "${TF_CUDA_COMPUTE_CAPABILITIES}" == "" ];then
    export TF_CUDA_COMPUTE_CAPABILITIES="6.2"
fi
if [ "${TF_CUDA_CLANG}" == "" ];then
    export TF_CUDA_CLANG="0"
fi

export TF_NEED_OPENCL=0
export TF_NEED_OPENCL_SYCL=0
export TF_DOWNLOAD_CLANG=0
export TF_NEED_KAFKA=0
export TF_ENABLE_XLA=0
export TF_NEED_VERBS=0
export TF_NEED_GDR=0
if [ "${CPU_OPT}" == 0 ];then
    export TF_NEED_MKL=0
else
    export TF_NEED_MKL=1
fi
export TF_DOWNLOAD_MKL=1
export TF_NEED_MPI=0
export TF_SET_ANDROID_WORKSPACE=0

export GCC_HOST_COMPILER_PATH=$(which gcc)
export CC_OPT_FLAGS="-march=native"

bazel clean

./configure

if [ "${CPU_OPT}" == 0 ];then
    bazel build \
        --config=cuda \
        --config=opt \
        --action_env PATH \
        --action_env LD_LIBRARY_PATH \
        --action_env DYLD_LIBRARY_PATH //tensorflow/tools/pip_package:build_pip_package
else
    bazel build \
        --config=cuda \
        --config=opt \
        --config=mkl \
        --config=monolithic \
        --copt=-mfpmath=both \
        --copt=-mavx \
        --copt=-mavx2 \
        --copt=-mfma \
        --copt=-msse4.1 \
        --copt=-msse4.2 \
        --action_env PATH \
        --action_env LD_LIBRARY_PATH \
        --action_env DYLD_LIBRARY_PATH //tensorflow/tools/pip_package:build_pip_package
fi

mkdir -p out

bazel-bin/tensorflow/tools/pip_package/build_pip_package out/tensorflow_pkg
