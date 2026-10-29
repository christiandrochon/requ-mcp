# language: fr
@api @US-128 @REQ-128
Fonctionnalité: Vérifier la conduite des voix d'un arrangement multi-pistes

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/ArrangementController.java:190 ; lyra-ml/app/main.py:3173 ; arrangement.py:2140-2250 (détection voice_leading)
  @AC-2 @api
  Scénario: Un arrangement sans défaut produit un rapport sans constat
    Quand j'envoie POST "/api/arrange/conduite-voix-arrangement" avec le corps JSON :
      """
      {"voix": [{"instrument":"violon","role":"mélodie principale","justification":"f","notes":[{"pitch":60,"duree_temps":1},{"pitch":62,"duree_temps":1},{"pitch":64,"duree_temps":1}]},
                {"instrument":"violoncelle","role":"basse","justification":"f","notes":[{"pitch":48,"duree_temps":1},{"pitch":47,"duree_temps":1},{"pitch":45,"duree_temps":1}]}]}
      """
    Alors la réponse a le statut 200
    Et la liste "violations" est vide

  # réf: lyra-api/generation/ArrangementController.java:190 ; lyra-ml/app/main.py:3173
  @AC-3 @api
  Scénario: Une quinte parallèle isolée est signalée, même avec la tolérance par défaut
    Quand j'envoie POST "/api/arrange/conduite-voix-arrangement" avec le corps JSON :
      """
      {"voix": [{"instrument":"violon","role":"mélodie principale","justification":"f","notes":[{"pitch":60,"duree_temps":1},{"pitch":62,"duree_temps":1}]},
                {"instrument":"violoncelle","role":"basse","justification":"f","notes":[{"pitch":53,"duree_temps":1},{"pitch":55,"duree_temps":1}]}]}
      """
    Alors la réponse a le statut 200
    Et la liste "violations" contient 1 éléments
    Et le champ "violations[0].piste_a" vaut "violon"
    Et le champ "violations[0].piste_b" vaut "violoncelle"
    Et le champ "violations[0].index_transition" vaut 1

  # réf: lyra-api/generation/ArrangementController.java:190 ; lyra-ml/app/main.py:3173 ; SEUIL_REPETITIONS_POWER_CHORD_PAR_DEFAUT = 3 (analyse_voice_leading.py:71)
  @AC-4 @api
  Plan du Scénario: Un enchaînement de power chords est toléré par défaut, signalé si la tolérance est désactivée (<tolerance>)
    Quand j'envoie POST "/api/arrange/conduite-voix-arrangement" avec deux pistes de guitare en quintes parallèles sur 5 notes et "tolerer_quintes_paralleles" <tolerance>
    Alors la réponse a le statut 200
    Et la liste "violations" <attendu>

    Exemples:
      | tolerance | attendu                      |
      | absent    | est vide                     |
      | true      | est vide                     |
      | false     | n'est pas vide               |
    # Données : piste A [40,42,44,45,47], piste B [47,49,51,52,54] (quinte juste constante sur 4 transitions)

  # réf: lyra-api/generation/ArrangementController.java:190 ; lyra-ml/app/main.py:3173 ; arrangement.py:2200-2203
  @AC-5 @api
  Scénario: Des pistes de longueurs différentes sont rejetées sans troncature silencieuse
    Quand j'envoie POST "/api/arrange/conduite-voix-arrangement" avec une piste de 3 notes et une piste de 2 notes
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée
