# WIK-DPS-TP02 : Ping API & Docker

Petite API HTTP écrite en **Go**, sans aucune dépendance externe (uniquement la
bibliothèque standard `net/http`).

Elle expose un unique endpoint qui renvoie, au format JSON, les en-têtes (headers)
de la requête reçue.

## Spécifications

| Requête      | Réponse                                       |
| ------------- | ---------------------------------------------- |
| `GET /ping` | `200 OK` + JSON des headers de la requête   |
| Tout le reste | `404 Not Found` avec un corps **vide** |

Le port d'écoute est configurable via la variable d'environnement
`PING_LISTEN_PORT`. En son absence, le serveur écoute sur le port **8080**.

## Prérequis

- [Go](https://go.dev/dl/) **1.22+**

Vérifier l'installation :

```bash
go version
```

## Lancement

### Avec le port par défaut (8080)

```bash
go run .
```

### Avec un port personnalisé

```bash
PING_LISTEN_PORT=3000 go run .
```

### Compiler un binaire autonome puis l'exécuter

```bash
go build -o ping-server .
PING_LISTEN_PORT=3000 ./ping-server
```

Le binaire produit est statique et autonome : il ne nécessite aucune dépendance
à l'exécution.

## Utilisation

Une fois le serveur lancé (exemple sur le port 8080) :

```bash
curl -i http://localhost:8080/ping
```

Exemple de réponse :

```http
HTTP/1.1 200 OK
Content-Type: application/json

{"Accept":["*/*"],"User-Agent":["curl/8.5.0"]}
```

Vérifier le comportement 404 (corps vide attendu) :

```bash
# Mauvaise méthode
curl -i -X POST http://localhost:8080/ping

# Mauvais chemin
curl -i http://localhost:8080/autre
```

> Remarque : chaque header est représenté par un **tableau de valeurs**, car un
> même en-tête HTTP peut légitimement apparaître plusieurs fois dans une requête.

## Tests

Les tests unitaires utilisent uniquement la stdlib (`net/http/httptest`) :

```bash
go test -v ./...
```

## Docker

### Image single-stage (`Dockerfile.single`)

Basée sur `golang:1.22-alpine`. Compile et exécute dans le même conteneur.

```bash
docker build -f Dockerfile.single -t wik-dps-tp02:single .
docker run -p 8080:8080 wik-dps-tp02:single
```

### Image multi-stage (`Dockerfile`)

Stage `builder` : `golang:1.22-alpine` compile un binaire statique.  
Stage final : `scratch` contient **uniquement** le binaire (pas de sources, pas de toolchain).

```bash
docker build -t wik-dps-tp02:multi .
docker run -p 8080:8080 wik-dps-tp02:multi
```

| Image  | Taille |
|--------|--------|
| single | ~448 MB |
| multi  | ~7 MB  |

Les deux images s'exécutent avec un utilisateur non-root (`appuser` / `nobody`).

### Optimisation des layers

`go.mod` est copié et `go mod download` lancé **avant** les sources : le layer de
dépendances n'est recalculé que si `go.mod` change, pas à chaque modification de code.

### Scan de sécurité (Trivy)

Les rapports complets sont disponibles dans `trivy-single.txt` et `trivy-multi.txt`.

| Image  | CRITICAL | HIGH | MEDIUM | LOW | UNKNOWN |
|--------|----------|------|--------|-----|---------|
| single | 2        | 19   | 14     | 21  | 0       |
| multi  | 1        | 14   | 23     | 2   | 3       |

Les vulnérabilités de l'image multi-stage proviennent uniquement du **Go stdlib**
embarqué dans le binaire (pas de paquets OS). Passer à Go 1.24+ résoudrait la CVE
critique `CVE-2025-68121` (crypto/tls).
