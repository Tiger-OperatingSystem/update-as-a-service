#!/usr/bin/env bash


cat > tiger-uaas-dev.sh <<\EOF
#!/usr/bin/env bash

GH_TOKEN="§TOKEN"

function createRelease(){
  curl \
  -X POST -s \
  -H "Content-Type:application/json" -H "Authorization: token ${GH_TOKEN}" \
  https://api.github.com/repos/§slug/releases \
  -d "{\"tag_name\":\"${tag_name}\"}"
}

function deleteRelease(){

  id=$(curl -s -H "Accept: application/vnd.github.v3+json" \
       "https://api.github.com/repos/§slug/releases/tags/${tag_name}" | \
       grep '§slug/releases/' | head -n1 | cut -d\/ -f 8 | cut -d\" -f1)
       
  curl \
  -X DELETE \
  -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GH_TOKEN}" \
  "https://api.github.com/repos/§slug/releases/${id}"
  
  curl \
  -X DELETE \
  -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GH_TOKEN}" \
  "https://api.github.com/repos/§slug/git/refs/tags/${tag_name}"
}

function bashlib.asURL() {
  # urlencode <string>
  old_lc_collate=$LC_COLLATE
  LC_COLLATE=C
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:$i:1}"
    case $c in
      [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
      *) printf '%%%02X' "'$c" ;;
    esac
  done
  LC_COLLATE=$old_lc_collate
}

function uploadfile(){
  info=$(curl -s -XGET --header "Authorization: token ${GH_TOKEN}" \
         "https://api.github.com/repos/§slug/releases/tags/${tag_name}")
         
  upload_url=$(echo "${info}" | head -n4 | tail -n1 | cut -d\" -f4 | cut -d\{ -f1)
  id=$(echo "${info}" | head -n 2 | tail -n1 | cut -d\" -f4 | cut -d\/ -f8)
  
  for FILE in "$@" ; do
    fullname="$(echo ${FILE} | cut -d\: -f1)"
    basename="$(echo ${FILE} | cut -d\: -f2)"
    curl -H "Authorization: token ${GH_TOKEN}" \
         -H "Accept: application/vnd.github.manifold-preview" \
         -H "Content-Type: application/octet-stream" \
         --data-binary "@${fullname}" \
         "$upload_url?name=$(bashlib.asURL "${basename}")"
    echo
  done
}

function help(){
  echo Pra usar é fácil:
  echo ${0} arquivo.deb \"Descrição em até 140 caracteres do que mudou\"
  exit 1
}

[ -z "${1}" ] && help
[ "${1}" = "-h" ] && help
[ "${1}" = "--help" ] && help
[ "${1}" = "/h" ] && help

[ ! -f "${1}" ] && {
  echo "Erro o arquivo '${1}' não existe!"
  exit 1
}

[ -z "${2}" ] && {
  echo "A descrição não pode ficar vazia!"
  exit 1
}

deb_file=$(readlink -f "${1}")

file_descriptor=$(mktemp)

package_name=$(dpkg-deb -I "${deb_file}"  | grep "Package:" | cut -d' ' -f3)
[ "${package_name}" = "" ] && {
  echo "Erro o arquivo '${1}' não é um pacote .deb válido!"
  exit 1
}
tag_name="${package_name}"

package_version=$(dpkg-deb -I "${deb_file}"  | grep "Version:" | cut -d' ' -f3)
[ "${package_version}" = "" ] && {
  echo "Erro o arquivo '${1}' não é um pacote .deb válido!"
  exit 1
}
version="${package_name}"

echo "${package_name}"    >  "${file_descriptor}"
echo "${package_version}" >> "${file_descriptor}"
echo "§Tiger-RELEASE"     >> "${file_descriptor}"
echo ${2}                 >> "${file_descriptor}"

deleteRelease
createRelease
uploadfile "${file_descriptor}:control.desc" "${deb_file}:contentes.ar"

EOF

cat > tiger-uaas-client.sh <<\EOF
#!/usr/bin/env bash

TIGER_RELEASE=21

available_packages=($(wget -q "https://api.github.com/repos/§slug/releases" -O - |\
                      grep '"tag_name":' | cut -d\" -f 4))
                      
for package in ${available_packages[@]}; do
  info=$(wget -q "https://github.com/§slug/releases/download/${package}/control.desc" -O -)
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
      "https://github.com/§slug/releases/download/${package}/contentes.ar"
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
EOF

tput reset

echo "----------------------------------------------------------------------------"
echo ""
echo "  Olá desenvolvedor, bem vindo a configuração do atualizador de recursos"
echo "  automatico"
echo ""
echo "-----------------------------------------------------------------------------"
echo ""
echo "  Pra começar, informe a release do sistema"
echo ""
TIGER_RELEASE=21
read -e -i "${TIGER_RELEASE}" -p "  > " TIGER_RELEASE

tput reset

echo "----------------------------------------------------------------------------"
echo ""
echo "  Olá desenvolvedor, bem vindo a configuração do atualizador de recursos"
echo "  automatico"
echo ""
echo "-----------------------------------------------------------------------------"
echo ""
echo "  Informe o slug do repositório no GitHub, se for desenvolvedor do Tiger OS,"
echo "  apenas pressione Enter"
echo ""
REPO_SLUG="Tiger-OperatingSystem/update-as-a-service"
read -e -i "${REPO_SLUG}" -p "  > " REPO_SLUG

tput reset

echo "----------------------------------------------------------------------------"
echo ""
echo "  Olá desenvolvedor, bem vindo a configuração do atualizador de recursos"
echo "  automatico"
echo ""
echo "-----------------------------------------------------------------------------"
echo ""
echo "  Por fim, informe o token de acesso para que o script possa fazer upload"
echo "  dos pacotes, você pode obter um em https://github.com/settings/tokens/new"
echo ""
echo "    Tenha certeza de fornecer as permissões assim:"
echo ""
echo "      [ ] repo"
echo "          [x] repo:status"
echo "          [x] repo_deployment"
echo "          [x] public_repo"
echo ""
echo ""
read -p "  > " GH_TOKEN

tput reset
echo "Gerando os scripts..."
sleep .5

sed -i "s|§TOKEN|${GH_TOKEN}|g;s|§Tiger-RELEASE|${TIGER_RELEASE}|g;s|§slug|${REPO_SLUG}|g" tiger-uaas-dev.sh
sed -i ";s|§Tiger-RELEASE|${TIGER_RELEASE}|g;s|§slug|${REPO_SLUG}|g" tiger-uaas-client.sh

chmod +x tiger-uaas-client.sh
chmod +x tiger-uaas-dev.sh

tput reset

echo "----------------------------------------------------------------------------"
echo ""
echo "  Tudo pronto!"
echo ""
echo "-----------------------------------------------------------------------------"
echo ""
echo "  Os scripts foram gerados, mas agora preste muita atenção!"
echo "  Foram gerados dois scripts:"
echo ""
echo "    - tiger-uaas-client.sh"
echo "    - tiger-uaas-dev.sh"
echo ""
echo "  > O script 'tiger-uaas-client.sh' deve ser distribuído junto com o sistema"
echo "  > O script 'tiger-uaas-dev.sh' NÃO pode ser redistribuído de forma alguma"
echo ""
echo "  Use sudo ./tiger-uaas-client.sh para atualizar os pacotes de outros devs"
echo "  Use ./tiger-uaas-dev.sh para empurrar atualizações dos seus pacotes"
echo ""