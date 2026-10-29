# language: fr
@api @US-112 @REQ-112
Fonctionnalité: Techniques de motif : ostinato, canon, développement, citation

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:1278 ; lyra-ml/app/main.py:5456 ; motif.py:637-675
  @AC-1 @api
  Scénario: Le canon renvoie le dux et une voix suiveuse décalée du délai demandé
    Quand j'envoie POST "/api/generate/canon" avec le corps JSON :
      """
      {"dux": [{"pitch":60,"duree_temps":1},{"pitch":62,"duree_temps":1},{"pitch":64,"duree_temps":1},{"pitch":65,"duree_temps":1}],
       "voix_comes": [{"technique": "retrograde", "decalage_temps": 2.0}]}
      """
    Alors la réponse a le statut 200
    Et les hauteurs de "dux" valent [60, 62, 64, 65]
    Et la liste "voix" contient 1 éléments
    Et le champ "voix[0].decalage_temps" vaut 2.0
    Et le champ "voix[0].technique" vaut "retrograde"
    # RÉSOLU (code + exécution de develop_motif) : rétrograde = ordre des hauteurs inversé ; [60,62,64,65] -> [65,64,62,60].
    Et les hauteurs de "voix[0].notes" valent [65, 64, 62, 60]

  # réf: lyra-api/generation/GenerationController.java:1311 ; lyra-ml/app/main.py:5506 ; motif.py:867-935
  @AC-2 @api
  Scénario: L'ostinato répète le module jusqu'à la durée totale
    Quand j'envoie POST "/api/generate/ostinato" avec le corps JSON :
      """
      {"module": [{"pitch":40,"duree_temps":0.5},{"pitch":43,"duree_temps":0.5}], "duree_totale": 8}
      """
    Alors la réponse a le statut 200
    Et la liste "couches" contient 1 éléments
    Et la somme des "duree_temps" de "couches[0].notes" vaut 8
    Et les hauteurs de "couches[0].notes" alternent [40, 43] sur toute la durée

  # réf: lyra-api/generation/TransformController.java:159 ; lyra-ml/app/main.py:5669 ; motif.py:2184-2210
  @AC-3 @api
  Scénario: La restriction ramène chaque note à la hauteur autorisée la plus proche
    Quand j'envoie POST "/api/transform/restriction-espace-generation" avec le corps JSON :
      """
      {"motif": [{"pitch":61,"duree_temps":1},{"pitch":66,"duree_temps":1},{"pitch":70,"duree_temps":1}],
       "pitches_autorises": [60, 64, 67]}
      """
    Alors la réponse a le statut 200
    Et les hauteurs de "motif_restreint" valent [60, 67, 67]
    Et les durées de "motif_restreint" sont celles de "motif_original"
