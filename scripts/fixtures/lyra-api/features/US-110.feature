# language: fr
@api @US-110 @REQ-110
Fonctionnalité: Vérifier la jouabilité d'un riff sur guitare 6, 7 ou 8 cordes

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/analysis/AnalysisController.java:171 ; lyra-ml/app/main.py:2872 ; jouabilite_guitare.py:174 ; AnalysisController.java:171
  @AC-2 @api
  Scénario: Un riff simple en accordage standard est jouable sans alerte
    Quand j'envoie POST "/api/analyze/jouabilite-guitare" avec le corps JSON :
      """
      {"motif": [{"pitch":40,"duree_temps":0.5},{"pitch":43,"duree_temps":0.5},{"pitch":45,"duree_temps":0.5}], "accordage": "standard"}
      """
    Alors la réponse a le statut 200
    Et le champ "jouable" vaut true
    Et la liste "problemes" est vide

  # réf: lyra-api/analysis/AnalysisController.java:171 ; lyra-ml/app/main.py:2872 ; jouabilite_guitare.py:221-243 (seuil 0.5 temps, 5 frettes)
  @AC-3 @api
  Scénario: Deux notes rapprochées exigeant un écart trop grand sont non jouables, avec le détail de l'écart
    # Mi2 (case 0) puis Mi3 : première position = corde grave case 12, écart 12 frettes > 5
    Quand j'envoie POST "/api/analyze/jouabilite-guitare" avec le corps JSON :
      """
      {"motif": [{"pitch":40,"duree_temps":0.25},{"pitch":52,"duree_temps":0.25}], "accordage": "standard"}
      """
    Alors la réponse a le statut 200
    Et le champ "jouable" vaut false
    Et un élément de "problemes" a "type_probleme" égal à "ecart_trop_grand" et "index_notes" égal à [0, 1]
    # RÉSOLU (code) : description est un texte libre ; oracle retenu : mention de « mm » et de « borne ».
    Et la "description" de ce problème mentionne un écart en "mm" et une borne

  # réf: lyra-api/analysis/AnalysisController.java:171 ; lyra-ml/app/main.py:2872 ; jouabilite_guitare.py:79,197-199
  @AC-4 @api
  Plan du Scénario: Entrées invalides refusées (<cas>)
    Quand j'envoie POST "/api/analyze/jouabilite-guitare" avec le corps JSON :
      """
      <corps>
      """
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée

    Exemples:
      | cas                      | corps                                                                                      |
      | motif vide               | {"motif": [], "accordage": "standard"}                                                      |
      | accordage inconnu        | {"motif": [{"pitch":40,"duree_temps":1}], "accordage": "ukulele"}                           |
      | longueur de corde nulle  | {"motif": [{"pitch":40,"duree_temps":1}], "accordage": "standard", "longueur_corde_pouces": 0} |
      | longueur de corde négative | {"motif": [{"pitch":40,"duree_temps":1}], "accordage": "standard", "longueur_corde_pouces": -5} |

  # réf: lyra-api/analysis/AnalysisController.java:171 ; lyra-ml/app/main.py:2872 ; hors_tessiture jouabilite_guitare.py:212-221
  @AC-4 @api
  Scénario: Une note hors tessiture produit un problème signalé, pas un refus
    Quand j'envoie POST "/api/analyze/jouabilite-guitare" avec le corps JSON :
      """
      {"motif": [{"pitch":100,"duree_temps":1}], "accordage": "standard"}
      """
    Alors la réponse a le statut 200
    Et un élément de "problemes" a "type_probleme" égal à "hors_tessiture"

  # réf: lyra-api/analysis/AnalysisController.java:171 ; lyra-ml/app/main.py:2872 ; ACCORDAGES_GUITARE jouabilite_guitare.py:41-48 (Si1 = MIDI 35)
  @AC-4 @api
  Scénario: La note grave Si1 est hors tessiture sur 6 cordes mais jouable sur 7 cordes
    Quand j'envoie POST "/api/analyze/jouabilite-guitare" avec le corps JSON :
      """
      {"motif": [{"pitch":35,"duree_temps":1}], "accordage": "standard"}
      """
    Alors un élément de "problemes" a "type_probleme" égal à "hors_tessiture"
    Quand j'envoie POST "/api/analyze/jouabilite-guitare" avec le corps JSON :
      """
      {"motif": [{"pitch":35,"duree_temps":1}], "accordage": "7_cordes"}
      """
    Alors le champ "jouable" vaut true
    Et la liste "problemes" est vide
