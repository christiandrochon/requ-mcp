# language: fr
@api @US-106 @REQ-106
Fonctionnalité: Harmoniser une mélodie pour un effectif de N pupitres avec conduite des voix

  Contexte:
    Soit l'API Lyra joignable
    Et la progression I-IV-V-I en "Do" "ionien" et sa mélodie soprano (fixture "progression-I-IV-V-I-do.json")

  # réf: lyra-api/generation/ArrangementController.java:77 ; lyra-ml/app/main.py:1615 ; chorale.py:303 ; détection voice_leading.detecter_quintes_octaves_paralleles
  @AC-2 @api
  Scénario: Aucune quinte ni octave parallèle entre deux voix
    Quand j'envoie POST "/api/arrange/chorale" avec la mélodie et les accords de la fixture
    Alors la réponse a le statut 200
    Et la liste "voix" contient 4 éléments
    Et aucune paire de voix ne forme de quinte ou d'octave parallèle entre deux accords consécutifs de "voix"

  # réf: lyra-api/generation/ArrangementController.java:77 ; lyra-ml/app/main.py:1615 ; chorale.py:192-232 (effectif, voix_generique)
  @AC-3 @api
  Scénario: Effectif de pupitres nommés : voix_generique renseignée, voix (SATB) vide
    Quand j'envoie POST "/api/arrange/chorale" avec la mélodie, les accords de la fixture et l'effectif :
      """
      [{"nom": "sopranos", "plage": [60, 81]}, {"nom": "altos", "plage": [55, 74]},
       {"nom": "ténors", "plage": [48, 69]}, {"nom": "basses", "plage": [40, 62]}]
      """
    Alors la réponse a le statut 200
    Et la liste "voix_generique" contient 4 éléments
    Et chaque élément de "voix_generique" a pour clés de "voix" exactement "sopranos, altos, ténors, basses"
    Et la liste "voix" est vide

  # réf: lyra-api/generation/ArrangementController.java:77 ; lyra-ml/app/main.py:1615
  @AC-3 @api
  Scénario: Sans effectif : voix (SATB) renseignée, voix_generique absente
    Quand j'envoie POST "/api/arrange/chorale" avec la mélodie et les accords de la fixture
    Alors la réponse a le statut 200
    Et la liste "voix" contient 4 éléments
    Et le champ "voix_generique" est absent ou nul

  # réf: lyra-api/generation/ArrangementController.java:77 ; lyra-ml/app/main.py:1615 ; ValueError chorale.py:404 / 593
  @AC-4 @api @risque-ecart @non-resolu
  Scénario: Une progression aux parallèles inévitables est refusée par une erreur nommant l'accord et la contrainte
    # A CONFIRMER : fixture "accords-parallelles-inevitables.json" à construire (progression dont aucun remplissage valide n'existe)
    Quand j'envoie POST "/api/arrange/chorale" avec la fixture "accords-parallelles-inevitables.json"
    Alors la requête est refusée
    # A CONFIRMER : la route /arrange/chorale n'est pas dans _PREFIXES_VALUEERROR_EN_400 (main.py:899) ; la ValueError y devient un 500 générique, relayé en 502 sans le message : l'oracle « erreur nommant l'accord (chiffrage et mesure) » risque de ne pas être observable
    Et le message d'erreur contient le chiffrage de l'accord, sa mesure et la contrainte en conflit
