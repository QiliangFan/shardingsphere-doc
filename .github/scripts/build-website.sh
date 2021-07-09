#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e  # exit scripts when errors occurred
script_path=$(cd `dirname $0`;pwd)
echo $script_path
root=`pwd` && cd $root
echo Root: $root

# codes reuse
build_docs(){
  # $1: source_dir wich contains build.sh
  # $2: branch or tag
  # $3: the destination of the `target` directory generated by build.sh

  if [ ! -d $3 ] ; then
    mkdir -p $3
  fi

  cd $1 && git checkout $2
  if ! [ -d $1/document -a -f $1/document/config.toml  ] ; then
    echo No avaiable docuemnts to build...
    echo PWD: `pwd`
    return -1
  fi

  echo modify config file $1/document/config.toml...
  if [ $2 == "master" ] ; then
    dst_dir=$root/document/master
    sed -i "s/\/document\/current/\/document\/master/g" $1/document/config.toml
    if [ -d $dst_dir ] ; then
      rm -rf $dst_dir/*
    fi
  else
    dst_dir=$root/document/legacy/$2
    sed -i "s/\/document\/current/\/document\/legacy\/$2/g" $1/document/config.toml
    sed -i "s/\/master\//\/$2\//g" $1/document/config.toml
    if [ -d $dst_dir ] ; then
      return 0  # nothing to do
    fi
  fi

  sh $1/build.sh
  src_dir=$1/target/document/current

  if [ ! -d $dst_dir ] ; then
    mkdir -p $dst_dir
  fi
  
  echo PWD `pwd`
  cp -rf $src_dir/* $dst_dir/
  rm -rf $src_dir
  cp -rf $1/target/* $3
  rm -rf $1/target
  return 1
}


echo config user shardingsphere
git config --global user.email "dev@shardingsphere.apache.org"
git config --global user.name "shardingsphere"

count=0
export TZ="Asia/Shanghai"

#######################################
##        SHARDINGSPHERE/DOCS        ##
#######################################
echo "[1] ====>>>> process shardingsphere/docs"
echo git clone https://github.com/apache/shardingsphere

git clone https://github.com/apache/shardingsphere _shardingsphere 

# ------------------------- build history docs --------------------------------------
if [ $RELEASE_UPDATE -gt 0 ] ; then
  cd _shardingsphere
  TAGS=(`git tag --sort=taggerdate -l | tac`// /)
  newest_tag=${TAGS[0]}
  echo Get the newest tag: $newest_tag
  git checkout $newest_tag > /dev/null
  cd ..
  echo build docs : [ $newest_tag ]
  build_docs $root/_shardingsphere/docs $newest_tag $root/sstarget
  if [ $? -gt 0 ] ; then
    echo New release docuemnt are built successful...
    git add .
    git commit -m "build document with tag $2"
    git push
  fi
  cd $root
fi
# -----------------------------------------------------------------------------------


echo check diff
if  [ ! -s old_version_ss ]  ; then
    echo init > old_version_ss 
fi
cd _shardingsphere
git log -1 -p docs > new_version_ss
diff ../old_version_ss new_version_ss > result_version
if  [ ! -s result_version ]  ; then
    echo "shardingsphere docs sources didn't change and nothing to do!"
    cd ..
else
    count=1
    echo "check shardingsphere something new, launch a build..."
    cd ..
    rm -rf old_version_ss
    mv _shardingsphere/new_version_ss ./old_version_ss
    
    echo build docs : [ master ]
    mkdir sstarget
    build_docs _shardingsphere/docs master sstarget
    cd $root
    
    echo copy community to dest dir
    if [ ! -d "community"  ];then
      mkdir -p community
    else
      echo community  exist
      rm -rf community/*
    fi
    cp -fr sstarget/community/* community
    
    echo copy blog to dest dir
    if [ ! -d "blog"  ];then
      mkdir -p blog
    else
      echo blog  exist
      rm -rf blog/*
    fi
    cp -fr sstarget/blog/* blog
fi
rm -rf sstarget
rm -rf _shardingsphere


#######################################
##  SHARDINGSPHERE-ELASTICJOB/DOCS   ##
#######################################
echo "[2] ====>>>> process shardingsphere-elasticjob/docs"
echo git clone https://github.com/apache/shardingsphere-elasticjob

git clone https://github.com/apache/shardingsphere-elasticjob _elasticjob 

echo check diff
if  [ ! -s old_version_ej ]  ; then
    echo init > old_version_ej 
fi
cd _elasticjob
git log -1 -p docs > new_version_ej
diff ../old_version_ej new_version_ej > result_version
if  [ ! -s result_version ]  ; then
    echo "elasticjob docs sources didn't change and nothing to do!"
    cd ..
    rm -rf _elasticjob
else
    count=2
    echo "check elasticjob something new, launch a build..."
    cd ..
    rm -rf old_version_ej
    mv _elasticjob/new_version_ej ./old_version_ej
    
    mkdir ejdocs
    cp -rf _elasticjob/docs/* ./ejdocs
    rm -rf _elasticjob
    
    echo build hugo elasticjob documents
    sh ./ejdocs/build.sh
    mkdir ejtarget
    cp -rf ejdocs/public/* ./ejtarget
    rm -rf ejdocs
    
    echo replace old files
    # Overwrite HTLM files
    echo copy elasticjob/current to dest dir
    if [ ! -d "elasticjob/current"  ];then
      mkdir -p elasticjob/current
    else
      echo elasticjob/current  exist
      rm -rf elasticjob/current/*
    fi
    cp -fr ejtarget/* elasticjob/current
    
    rm -rf ejtarget
    #ls -al
fi


if [ $count -eq 0 ];then
    echo "Both ShardingSphere&ElasticJob docs are not Changed, Skip&Return now."
else
    echo git push new files
    git add .
    export TZ="Asia/Shanghai"
    dateStr=`date "+%Y-%m-%d %H:%M:%S %Z"`
    git commit -m  "Update shardingsphere documents at $dateStr."
    git push
fi
