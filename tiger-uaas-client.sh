#!/usr/bin/env bash

TIGER_RELEASE=21

available_packages=($(wget -q "https://api.github.com/repos/Tiger-OperatingSystem/update-as-a-service/releases" -O - |\
                      grep '"tag_name":' | cut -d\" -f 4))
                      
for package in ${available_packages[@]}; do
  info=$(wget -q "https://github.com/Tiger-OperatingSystem/update-as-a-service/releases/download/${package}/control.desc" -O -)
  package_name=$(echo "${info}" | head -n1)
  online_version=$(echo "${info}" | head -n2 | tail -n1)
  installed_version=$(dpkg -l | grep ^ii | awk '{print $2,$3}' | grep ^"${package_name} " | cut -d' ' -f2)
  
  target_release=$(echo "${info}" | head -n3 | tail -n1)
  
  [ ! "${target_release}" = "${TIGER_RELEASE}" ] && {
    echo "O pacote '${package_name}' não foi feito para a release atual"
    continue
  }
  
  latest_version=$(echo -e "${online_version}\n${installed_version}" | sort -V | tail -n1)
  
  # Só faça alguma coisa se as versões online e local forem  diferentes
  [ ! "${installed_version}" = "${online_version}" ] && {
    [ "${latest_version}" = "${online_version}" ] && {
      echo "${package_name}: local=${installed_version} online=${online_version}"
      echo "Baixando..."
      
      wget -q -c --show-progress --progress=bar:force:noscrol \
      "https://github.com/Tiger-OperatingSystem/update-as-a-service/releases/download/${package}/contentes.ar"
      echo "Extraindo..."
      dpkg -x contentes.ar .
      rm contentes.ar
      echo 
    }
  }
done

echo "Instalando..."
cp -rlf ./* /
rm -rf ./*


