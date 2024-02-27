

echo "Enter a project name that is used to generate resource names:" &&
read projectName &&

resourceGroupName="${projectName}rg" &&
storageAccountName="${projectName}store" &&
containerName="templates" &&

key=$(az storage account keys list -g "tutorial" -n $storageAccountName --query [0].value -o tsv) &&

sasToken=$(az storage container generate-sas --account-name $storageAccountName --account-key $key --name $containerName --permissions r --expiry `date -u -v+2H '+%Y-%m-%dT%H:%MZ'`) &&
sasToken=$(echo $sasToken | sed 's/"//g')&&

blobUri=$(az storage account show -n $storageAccountName -g "tutorial" -o tsv --query primaryEndpoints.blob) &&
templateUri="${blobUri}${containerName}/azuredeploy.json" &&

az deployment group create --name DeployLinkedTemplate --resource-group "tutorial" --template-uri $templateUri --parameters projectName=$projectName --query-string $sasToken --verbose