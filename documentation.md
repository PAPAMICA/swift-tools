# Préparation de l'environnement

## Installation des clients 
```
pip install python-openstackclient python-keystoneclient python-swiftclient
```

# Gestion des containers
## Lister les containers
```
swift list
```
ou
```
openstack container list
```

## Lister les policies
```
swift info --json | jq -r '.swift.policies[].name'
```

## Créer un container
```
swift post <container-name> [-H 'X-Container-Read: .r:*'] [-H 'X-Storage-Policy: <policy-name>']
```
ou 
```
openstack container create [--public] [--storage-policy <policy-name>] <container-name> 
```

## Supprimer un container
```
swift delete <container>
```
ou 
```
openstack container delete [--force] <container>
```

# Gestion des objects
## Lister les objects
```
swift list <container>
```
ou
```
openstack object list <container>
```

## Envoyer un object
```
swift upload <container> <fichier ou dossier>
```
ou 
```
openstack object create <container> <fichier>
```

## Télécharger un object
```
swift download <container> <fichier>
```
Vous pouvez aussi télécharger tous les objects avec le même chemin :
```
swift download <container> --prefix <chemin>
```

## Supprimer un object
```
swift delete <container> <object> 
```
ou 
```
openstack object delete <container> <object>
```
Vous pouvez aussi supprimer tous les objects avec le même chemin :
```
swift delete <container> <chemin>/*





