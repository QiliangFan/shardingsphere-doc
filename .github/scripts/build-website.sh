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

root=`pwd` && cd $root

# codes reuse
build_docs(){
  # $1: branch or tag

  git checkout $1
  if [ ! -d $1 ] ; then
    echo No avaiable docuemnts to build...
    return 0
  fi

  if ! [ -d $1/document -a -f $1/document/config.toml  ] ; then
    echo No avaiable docuemnts to build...
    echo PWD: `pwd`
    return 0
  fi

  echo modify config file docs/document/config.toml...
  dst_dir=../document/$1
  sed -i "s/\/document\/current/\/document\/$1/g" docs/document/config.toml
  sed -i "/editURL/d" docs/document/config.toml
  if [ -d $dst_dir ] ; then
    git stash
    return 0  # nothing to do
  else
      cd ..
      sed -i -r 's/(<!--AUTO-DEPLOY-DOC-->)/\1\n                <a class="i-drop-list" href="https:\/\/shardingsphere.apache.org\/document\/'$1'\/en\/overview"\n                  target="_blank">'$1'<\/a>/g' index.html
      sed -i -r 's/(<!--AUTO-DEPLOY-DOC-->)/\1\n            <a class="i-drop-list" href="https:\/\/shardingsphere.apache.org\/document\/'$1'\/en\/overview"\n              target="_blank">'$1'<\/a>/g' index_m.html
      sed -i -r 's/(<!--AUTO-DEPLOY-DOC-->)/\1\n                <a class="i-drop-list" href="https:\/\/shardingsphere.apache.org\/document\/'$1'\/cn\/overview"\n                  target="_blank">'$1'<\/a>/g' index_zh.html
      sed -i -r 's/(<!--AUTO-DEPLOY-DOC-->)/\1\n            <a class="i-drop-list" href="https:\/\/shardingsphere.apache.org\/document\/'$1'\/cn\/overview"\n              target="_blank">'$1'<\/a>/g' index_m_zh.html
      cd _shardingsphere
  fi

  sh docs/build.sh
  src_dir=docs/target/document/current
  cd ..
  find $src_dir -name '*.html' -exec sed -i -e 's|<option id="\([a-zA-Z]\+\)" value="/document/current|<option id="\1" value="/document/'$1'|g' {} \;

  if [ ! -d $dst_dir ] ; then
    echo mkdir $dst_dir
    mkdir -p $dst_dir
  fi
  
  echo CP from $src_dir to $dst_dir
  cp -rf $src_dir/* $dst_dir/
  rm -rf $src_dir

  git stash
  return 0
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
cd _shardingsphere
TAGS=(`git tag --sort=taggerdate -l '*-doc'`)
echo ${TAGS[@]}
if [ ${#TAGS} -gt 0 ] ; then
  count=1
  for tag in ${TAGS[@]}
  do
    echo Get the tag: $tag
    echo build docs : [ $tag ]
    build_docs $tag ;
  done
fi
cd $root

# -----------------------------------------------------------------------------------
echo check diff
if  [ ! -s old_version_ss ]  ; then
    echo init > old_version_ss 
fi
cd _shardingsphere
git checkout master
git log -1 -p docs > new_version_ss
diff ../old_version_ss new_version_ss > result_version

if  [ ! -s result_version ]  ; then
    echo "shardingsphere docs sources didn't change and nothing to do!"
    cd ..
else
    count=2
    echo "check shardingsphere something new, launch a build..."
    cd ..
    rm -rf old_version_ss
    mv _shardingsphere/new_version_ss ./old_version_ss
    
    cp -rf _shardingsphere/docs ./
    rm -rf _shardingsphere
    mv docs ssdocs
    
    echo build hugo ss documents
    sh ./ssdocs/build.sh
    cp -rf ssdocs/target ./
    rm -rf ssdocs
    mv target sstarget
    
    echo replace old files
    # Overwrite HTLM files
    echo copy document/current to dest dir
    if [ ! -d "document/current"  ];then
      mkdir -p document/current
    else
      echo document/current  exist
      rm -rf document/current/*
    fi
    cp -fr sstarget/document/current/* document/current
    
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
      rm -rf iblog/*
    fi
    cp -fr sstarget/blog/* blog
    
    rm -rf sstarget
fi

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
    count=3
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
