#!/bin/sh
# Copyright (c) 2018 FurtherSystem Co.,Ltd. All rights reserved.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; version 2 of the License.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1335  USA

source `dirname $0`/common.env

source ~/.bash_profile
HOME_PATH=${HOME}
ENTRY_POINT_MAIN=${REPO_ROOT_PATH}/cmd/vql/main.go
GOCC=go
GOXC=gox
GIT_COMMIT=$(git rev-parse --short HEAD)
LD_FLAGS="-X vql/internal/defs.Version=${IMAGE_VERSION}.${IMAGE_RELEASENO} -X vql/internal/defs.Shorthash=${GIT_COMMIT} ${LD_FLAGS}"
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
SOURCES_PATH=${REPO_ROOT_PATH}/build/rpms/SOURCES
ORIGIN_SOURCES_PATH=${REPO_ROOT_PATH}/build/rpms/SOURCES/${IMAGE_FULLNAME}.tar.gz
ORIGIN_SPECS_PATH=${REPO_ROOT_PATH}/build/rpms/SPECS/${IMAGE_FULLNAME}.spec
ORIGIN_RPMS_PATH=${REPO_ROOT_PATH}/build/rpms/RPMS/${IMAGE_ARCH}
RPMBUILD=rpmbuild
RPMBUILD_ROOT_PATH=${HOME}/${RPMBUILD}/
RPMBUILD_SOURCES_PATH=${HOME}/${RPMBUILD}/SOURCES/
RPMBUILD_SPECS_PATH=${HOME}/${RPMBUILD}/SPECS/${IMAGE_FULLNAME}.spec
RPMBUILD_RPMS_PATH=${HOME}/${RPMBUILD}/RPMS/${IMAGE_ARCH}/

#XC_ARCH=${XC_ARCH:-"386 amd64 arm"}
#XC_OS=${XC_OS:-linux darwin windows freebsd openbsd solaris}
#XC_EXCLUDE_OSARCH="!darwin/arm !darwin/386"

if [[ -n "${OR_STRIP}" ]]; then
    LD_FLAGS="-s -w ${LD_FLAGS}"
fi

# clean directories
rm -rf ${REPO_ROOT_PATH}/bin/${IMAGE_NAME_MAIN}
rm -rf ${REPO_ROOT_PATH}/pkg/*
rm -rf ${SOURCES_PATH}/*
rm -rf ${ORIGIN_RPMS_PATH}
rm -rf ${HOME}/${RPMBUILD}/SPECS/*.spec
rm -rf ${HOME}/${RPMBUILD}/SOURCES/*.tar.gz
rm -rf ${HOME}/${RPMBUILD}/RPMS/${IMAGE_ARCH}

# preprocess here.
echo ${GOCC} test -v ./... 
${GOCC} test -v ./...

echo ${GOCC} build -o ${REPO_ROOT_PATH}/bin/${IMAGE_NAME_MAIN} -ldflags \"${LD_FLAGS}\" ${ENTRY_POINT_MAIN}
${GOCC} build -o ${REPO_ROOT_PATH}/bin/${IMAGE_NAME_MAIN} -ldflags "${LD_FLAGS}" ${ENTRY_POINT_MAIN}

mkdir -p ${SOURCES_PATH}/${IMAGE_FULLNAME}
cp ${REPO_ROOT_PATH}/bin/${IMAGE_NAME_MAIN} ${SOURCES_PATH}/${IMAGE_FULLNAME}/
cp ${REPO_ROOT_PATH}/configs/${IMAGE_NAME_MAIN}-boot.sh ${SOURCES_PATH}/${IMAGE_FULLNAME}/
cp ${REPO_ROOT_PATH}/configs/${IMAGE_NAME_MAIN}.service ${SOURCES_PATH}/${IMAGE_FULLNAME}/
cp ${REPO_ROOT_PATH}/configs/${IMAGE_NAME_MAIN}.env ${SOURCES_PATH}/${IMAGE_FULLNAME}/
cp ${REPO_ROOT_PATH}/LICENSE ${SOURCES_PATH}/${IMAGE_FULLNAME}/

cd ${SOURCES_PATH}
tar zcvf ${IMAGE_FULLNAME}.tar.gz ${IMAGE_FULLNAME}
cd -

cd ${REPO_ROOT_PATH}

cp ${ORIGIN_SOURCES_PATH} ${RPMBUILD_SOURCES_PATH} || die "${ORIGIN_SPECS_PATH} ${RPMBUILD_SOURCES_PATH} copy failed"
cp ${ORIGIN_SPECS_PATH} ${RPMBUILD_SPECS_PATH} || die "${ORIGIN_SPECS_PATH} ${RPMBUILD_SPECS_PATH} copy failed"
${RPMBUILD} -bb --clean ${RPMBUILD_SPECS_PATH} || die "rpmbuild failed"

mkdir -p ${ORIGIN_RPMS_PATH}/ || die "mkdir failed"
cp ${RPMBUILD_RPMS_PATH}/${IMAGE_FULLNAME}.rpm ${ORIGIN_RPMS_PATH}/ || die "copy failed"

cd ${RET_DIR}
