Je souhaite développer un jeu en m'inspirant de Factorio et de Foundry.
Je code sur godot, en utilisant le camelCase (sauf pour les fonctions natives) et en anglais
Mon projet est de créer un jeu sous forme de factory building et management, je souhaite que la map possède des biomes et des ressources, que le joueur va récupérer ces ressources générés sous forme de clusters avec différentes règles appliqués, et il pourra alors fabriquer des items manuellement, puis automatiser ça avec des machines. Ces items aideront le joueur ou pourront être vendus à des NPCs (pas encore sûr de si c'est des personnages ou des bâtiments).

Le jeu est composé de tiles, chacunes faisant 16x16 pixels, et regroupées sous forme de chunks de 16x16 tiles.

Pour l'histoire du jeu, je manque le début, mais je souhaite que le joueur créé une entreprise de production à grande échelle, couvrant de tout et n'importe quoi : meubles, électronique, poterie, culture agricole.. et que cette entreprise soit en compétition avec d'autres entreprises IA (et pourquoi pas joueur mais dans un trèèèèss lointain futur) pour être la plus riche
La vente se fera à des entités (personnage ou entreprise ou bâtiment, des choses comme ça), celles-ci auront des factions qui influeront le prix d'achat ou de vente selon la relation qu'ils entretiennent avec l'entreprise du joueur.
Par ailleurs, ces entités pourront acheter ou vendre soit de tout (à différents niveaux/tiers de complexité, par exemple ils ne vont pas acheter une chaise et un objet sophistiqué électronique, mais cela n'empêche pas l'électrique comme par exemple des lampes, ou alors par rapport au luxe, ils ne vont pas acheter une vieille chaise et un majestueux chandelier (exception s'ils sont dans l'acaht de chaises, là ils pourraient acheter toute catégorie de chaise)).
Chaque produit aura une valeur de base qui fluctuera avec le temps (par exemple chaque "saison" même s'il n'y a pas de saison, mais c'est un exemple), dépendra aussi de ce que le joueur vend (par exemple, un item qui vaut 50 par unité alors le joueur le vendra 50 d'argent, s'il en vend 100 ça sera 40, s'il en vend 1000 ça sera 30.. tout ceci sera sur un laps de temps donné, et pas "toutes les 5 min, le prix sera remis à sa valeur de base", mais plutôt "s'il vend en moyenne 100 unités par minute sur les 15 dernières minutes alors le prix baissera de tant") et aussi de la relation qu'il a avec l'entité + la faction correspondante (qui rajoute un bonus/malus en %)

Au niveau de l'automatisation :
Il y aura plusieurs types de bâtiments selon les besoins (usines, fonderies, manufacture mais aussi bûcherons, mines..) sachant que chaque usine pourra fabriquer presque tout tant que c'est inférieur ou égal au tier de l'usine (une usine tier 2 pourra fabriquer des items de tier 1 ou 2, mais pas de tier 3 ou plus)
Je souhaite aussi qu'il y ait un système d'arbre de recherche, un pour les bâtiments pour les améliorer (+5% de vitesse, +1 module d'amélioration, déblocage du tier suivant..) je ne sais pas encore si ça sera de manière générale ou alors pour un bâtiment spécial, mais aussi pour le joueur (bouge + vite, casse + vite, fabrique + vite, + d'inventaire...)
Je ne sais pas encore si le déblocage de tier suivant voire la globalité de l'arbre de recherche devrait juste être un arbre de recherche (genre dans un bâtiment), ou alors pour les bâtiments que ça soient des entités qui les donnent, ça peut être en fonction de la relation que le joueur a avec et aussi le nombre d'objets vendus (pas en total, mais par exemple 50 chaises, 50 tables..)
Le déplacement de ressources entre bâtiments se fera soit par tapis roulant, soit par robot, soit les deux (ce qui ressemble pas mal à Factorio), sachant que tous deux sont aussi améliorables avec l'arbre de recherche

Pour le moment, tout ce que j'ai c'est une génération de terrain procédurale avec un seul biome (juste de l'herbe) et des clusters de minerais éparpillés un peu partout, avec un joueur pouvant bouger et générer du terrain s'il s'approche au bord d'un chunk

Voici tous le code que j'ai pour le moment :

# Projet Godot – Récapitulatif des Scripts

## 1. `player.gd`

**Classe** : `Player` (extends `Node2D`)  
**Responsabilité** : Gérer le déplacement du joueur.

### Attributs
- `speed: int` — vitesse de déplacement (200 par défaut).

### Fonctions
- `func _ready() -> void`  
  - Affiche `“Player loaded”` dans la console.
- `func _process(delta: float) -> void`  
  - Appel à `move(delta)` chaque frame.
- `func move(delta: float) -> void`  
  1. Lit les entrées de direction (`moveUp`, `moveDown`, `moveLeft`, `moveRight`).  
  2. Sprint si `SHIFT` est enfoncé (`speed = 800`).  
  3. Normalise le vecteur de mouvement.  
  4. Met à jour `position` du node en fonction de `speed` et `delta`.

---

## 2. `playerCam.gd`

**Classe** : `PlayerCam` (extends `Camera2D`)  
**Responsabilité** : Suivre le joueur et gérer le zoom.

### Attributs
- `@export var playerPath: NodePath` — chemin vers le node `Player`.  
- `var player: Node2D` — référence au joueur.  
- `var margin: float = 0.2` — marge de la zone morte (20 % de l’écran).

### Fonctions
- `func _ready() -> void`  
  - Récupère `player` via `playerPath`, positionne la caméra sur lui et appelle `make_current()`.
- `func _process(delta: float) -> void`  
  1. Zoom avant/arrière sur touches `zoomIn`/`zoomOut`, clampé entre `0.3` et `2.0`.  
  2. Si le joueur sort de la marge horizontale/verticale, déplace lentement la caméra vers le joueur.

---

## 3. `layerHolder.gd`

**Classe** : `LayerHolder` (extends `Node2D`)  
**Responsabilité** : Génération et affichage du monde, des chunks et des ressources.

### Attributs
- **TileMapLayers** (via `@onready`):  
  - `backgroundWallpaper: TileMapLayer`  
  - `backgroundLayer:     TileMapLayer`  
  - `resourcesLayer:      TileMapLayer`  
  - `hiddenResourcesLayer: TileMapLayer`  
  - `chunkOutline:        TileMapLayer`  
- `player:       Node2D` — référence au node `Player`.  
- `playerChunkPos: Vector2i` — chunk actuel du joueur.  
- `toggleChunkOutline: bool` — affichage du contour des chunks.  
- `generatedChunks: Dictionary<Vector2i, bool>` — chunks déjà générés.  
- **Ressources**:  
  - `resourceMap:               Dictionary<Vector2i, ResourceInstance>`  
  - `blockedChunksByResource:   Dictionary<int, Dictionary<Vector2i, bool>>`  
  - `clusterMap:                Dictionary<Vector2i, ClusterInstance>`  
- `tileInfo:     Array` — données JSON des tuiles de sol.  
- `resourceInfo: Array` — données JSON des tuiles de ressources.  
- `time: float`, `reg: float` — variables de test/debug.

### Fonctions principales

1. **Cycle de vie**  
   - `func _ready() -> void`  
     • Initialise `z_index` des calques.  
     • Appelle `generateWorld(...)` autour du spawn.  
   - `func _process(delta: float) -> void`  
     • Met à jour `playerChunkPos`.  
     • Si changement de chunk : appelle `generateWorld(...)`.  
     • Bascule l’affichage de `chunkOutline` sur action.

2. **Génération monde**  
   - `func generateWorld(from: Vector2i, to: Vector2i) -> void`  
     • `await generateResources_async(...)` puis `generateBackgroundWallpaper_async(...)`.  
     • Pour chaque chunk non généré :  
       – Remplit `backgroundLayer` avec `tileInfo`.  
       – Trace le contour via `chunkOutline`.  
       – Affiche les ressources cachées via `showResoucesOnChunk()`.  
       – Marque le chunk comme généré.

3. **Génération ressources**  
   - `func generateResources_async(from: Vector2i, to: Vector2i) -> void`  
     • Étend la zone de génération selon `defaultMaxRadius`.  
     • Mélange l’ordre des chunks (`shuffle()`), throttle avec `await process_frame`.  
     • Pour chaque chunk non en `clusterMap` :  
       – Calcule `radius` + `minClusterDistance`.  
       – Pour chaque type `res in resourceInfo` :  
         · Si `canGenerateClusterAt()` → crée un `ClusterInstance`,  
           récupère `tilesCreated`, met à jour `clusterMap` & `resourceMap`, place dans `hiddenResourcesLayer`.

4. **Génération fond**  
   - `func generateBackgroundWallpaper_async(from: Vector2i, to: Vector2i) -> void`  
     • Détermine zone étendue.  
     • Remplit `backgroundWallpaper` case par case, throttle avec `await process_frame`.

5. **Helpers**  
   - `isChunkGenerated(chunk)`, `markChunkGenerated(chunk)`  
   - `showChunkOutline(toggle)`  
   - `getChunkOfTile(pos) -> Vector2i`  
   - `canGenerateClusterAt(pos, id, rad) -> bool`  
   - `updateMapFromClusterPlaced(cluster)`  
   - `showResoucesOnChunk(chunk)`  
   - `print_generated_chunks()`

---

## 4. `jsonLoader.gd`

**Classe** : `JsonLoader` (extends `Node`)

### Fonctions
- `static func loadJson(path: String) -> Array`  
  • Ouvre et lit un fichier JSON.  
  • Retourne le résultat de `JSON.parse_string()` (Array ou Dictionary).

---

## 5. `globals.gd` (Singleton `Globals`)

**Classe** : `Globals` (extends `Node`)

### Attributs
- **Tailles & distances**  
  - `chunkSize: int` — 16 tuiles par chunk  
  - `tileSize:  int` — 16 px par tuile  
  - `loadedChunkDistance: int` — 15 chunks de rayon  
- **Ressources**  
  - `defaultMinRichness: int = 15 000`  
  - `defaultMaxRichness: int = 15 000 000`  
  - `defaultMinDistance:  int = 120`  
  - `defaultMaxDistance:  int = 8 000`  
  - `defaultMinRadius:    int = 5`  
  - `defaultMaxRadius:    int = 50`

---

## 6. `clusterClass.gd`

**Classe** : `ClusterInstance` (extends `RefCounted`)

### Attributs
- `id: int` — type de ressource.  
- `origin: Vector2i` — position centrale du cluster.  
- `radius: int` — rayon en tuiles.  
- `maxRichness: int` — richesse totale maximale calculée.  
- `positions: Dictionary<Vector2i, ResourceInstance>` — tuiles générées.  
- `totalRichness: int` — (non utilisée actuellement).

### Fonctions
- `func _init(_origin, _id, _radius)`  
  • Calcule `maxRichness` selon `log(distFromCenter)`, clampé.  
- `func generateResources() -> Dictionary`  
  • Flood‑fill depuis `origin`, probabilité selon `getTileProbability()`.  
  • Appelle `removeUniqueEmpty()`, puis `distributeRichness()`.  
  • Retourne `positions`.  
- `func removeUniqueEmpty(visitedTiles)`  
  • Ajoute des tuiles isolées si elles ont ≥ 3 voisins.  
- `func getDistanceTier(dist, rad) -> int`  
  • Retourne 1/2/3 selon la tier (tiers égaux).  
- `func getTileProbability(tier, pos) -> float`  
  • Probabilité de base (1.0 / 0.6 / 0.3) + bonus voisin (0.15 chacun), clamp 0.85.  
- `func calculateTileRichness(dist, rad, maxValue) -> int`  
  • % de richesse selon distance (tiers 90–100% → 50–90% → 0–50%).  
- `func distributeRichness() -> void`  
  • Répartit `maxRichness` uniformément, pondéré par `lerp` tiers (1.0→0.0).  
  • Ajuste pour les arbres (`id == 0`).  
  • Remplit `richnessThreshold` et appelle `updateState()`.

---

## 7. `resourceClass.gd`

**Classe** : `ResourceInstance` (extends `RefCounted`)

### Attributs
- `id: int` — type de ressource.  
- `richness: int` — richesse courante.  
- `richnessThreshold: Array<int>` — seuils 0→7.  
- `state: int` — état (7 = plein, 0 = vide).  
- `sprite: Vector2i` — coordonnées atlas (x = variante, y = état).  
- `position: Vector2i` — position globale sur la TileMap.

### Fonctions
- `func _init(_id, _richness, _position)`  
  • Initialise `id`, `richness`, `position`.  
  • Sélectionne une colonne aléatoire (`randi_range`) dans l’atlas pour `sprite.x`.  
- `func isInteracted() -> void`  
  • Décrémente `richness`, appelle `updateState()`.  
- `func updateState() -> void`  
  • Si `richness < richnessThreshold[state]`, décrémente `state` et met à jour `sprite.y`.  
- `func updateSprite() -> void`  
  • Sync `sprite.y` avec `state`.

---

## 8. Fichiers JSON

### `tiles/groundTiles.json`
```json
[
  {
    "id": 0,
    "name": "grass",
    "texture": "res://assets/tiles/ground/grass.png",
    "baseProbability": 0.7,
    "tileAtlasSize": [1.1]
  }
]
```

### `tiles/resourceTiles.json`
```json
[
  {
    "id": 0,
    "name": "tree",
    "texture": "res://assets/tiles/resources/tree.png",
    "tileAtlasSize": [1.1]
  },
  {
    "id": 1,
    "name": "stone",
    "texture": "res://assets/tiles/resources/stone.png",
    "tileAtlasSize": [1.1]
  },
  {
    "id": 2,
    "name": "coalOre",
    "texture": "res://assets/tiles/resources/coalOre.png",
    "tileAtlasSize": [1.1]
  },
  {
    "id": 3,
    "name": "copperOre",
    "texture": "res://assets/tiles/resources/copperOre.png",
    "tileAtlasSize": [1.1]
  },
  {
    "id": 4,
    "name": "ironOre",
    "texture": "res://assets/tiles/resources/ironOre.png",
    "tileAtlasSize": [1.1]
  },
  {
    "id": 5,
    "name": "clay",
    "texture": "res://assets/tiles/resources/clay.png",
    "tileAtlasSize": [1.1]
  }
]
```
---

## 9. Tilesets

- background.tres         → utilisé par background (TileMapLayer)
- chunkBorder.tres        → utilisé par chunkOutline (TileMapLayer)
- defaultWallpaper.tres   → utilisé par backgroundWallpaper (TileMapLayer)
- resourcesOres.tres      → utilisé par hiddenResources + resources (TileMapLayers)

---

## 10. Arborescence de la scène

MainScene (Node2D)  
├─ LayerHolder (Node2D)  
│  ├─ backgroundWallpaper (TileMapLayer)  
│  ├─ background           (TileMapLayer)  
│  ├─ resources            (TileMapLayer)  
│  ├─ hiddenResources      (TileMapLayer)  
│  └─ chunkOutline         (TileMapLayer)  
├─ Player (Node2D)  
│  └─ PlayerSprite (Sprite2D)  
└─ PlayerCam (Camera2D)  

- `MainScene` : Racine de la scène principale.  
- `LayerHolder` : Gère les TileMapLayers et la génération du monde.  
- `Player` : Déplacement du joueur.  
- `PlayerCam` : Caméra qui suit le joueur, avec zoom dynamique.


Pour le moment, je veux que le jeu possède :
- Un terrain sur lequel bouger
- Des ressources à récupérer
- Pouvoir fabriquer des trucs
- Vendre ces trucs à un NPC/entité lambda
- Automatiser la production de ces trucs

Ensuite, je voudrais par étape :
1. 	- Ajouter des missions comportant les items demandés (ça peut être plusieurs type d'items) et la récompense
	- Ajouter une progression (sous forme de tier, voir PS1)

2.	- Ajouter une notion de coût en énergie (voir PS2)
	- Ajouter la fluctuation de l'économie par rapport au temps
	- Ajouter différentes entitées spécialisées dans un certain type d'item

3.	- Mettre une valeur de relation entre entité et joueur qui influe sur le prix
	- Changer le prix par rapport à la vente/min

4.	- Mettre des biomes dans la génération, certains favorisant l'apparition de cluster ou alors la vitesse de production
	  (par exemple, un biome chaud pourrait augmenter la production d'énergie thermale, là où un biome froid la réduirait, idem avec les plantations)


PS1: Appliquer une notion de progression, plutôt que pouvoir tout faire dès le début, commencer avec des choses de qualité médiocre puis de mieux en mieux, y compris le tier des usines et compagnie (sans pour autant avoir l'arbre de recherche, juste avoir bâtiments tiers 1 qui craft tier 1, puis une fois qu'on a les ressources/conditions requises on peut tier 2)

PS2: L'énergie pourrait être achetée avec l'argent gagné, ou alors produite avec de la chaleur, de la lumière...

Dans tout ça, il me manque des manières de dépenser l'argent
Pour l'instant, je n'ai que :
-> Dans les améliorations


Plus tard, je souhaiterai y ajouter des améliorations :
- Créer des sauvegardes et les charger
- Ajouter des paramètres que le joueur pourra changer (globaux comme volume ou contrôles, tout comme en jeu comme densité des clusters, modifier l'économie...)
- Ajouter une logique aux bots, je m'y suis pas attardé car cela sera pour plus tard quand la base sera fini, mais ça sera clic du point A au point B, puis auto detect ce qu'il faut prendre selon ce que demande le point B
- Plutôt que de baser l'économie sur de la vente pure, cela pourrait être intéressant d'avoir les entités donner des missions ou des demandes que toutes les entreprises peuvent remplir (par exemple ils demandent d'avoir 45 chaises en tel temps), cela améliorera la relation avec cette entité, et aussi celle avec la faction mais bien moins important
  Rien n'empêche d'avoir quand même la vente en bloc comme avant, sauf que celle-ci rapporterait moins, et les missions données par les entités rapporteront plus
