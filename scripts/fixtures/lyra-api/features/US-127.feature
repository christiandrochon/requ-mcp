# language: fr
@api @US-127 @REQ-127
Fonctionnalité: Détecter la surcharge d'un arrangement

  Contexte:
    Soit l'API Lyra joignable

  # CORRIGÉ (test) : le contrat réel de notes_simultanees est une liste de couples [instrument, pitch] (lyra-ml SurchargeRegistreRequest), pas des objets.
  # réf: lyra-api/analysis/AnalysisController.java:182 ; lyra-ml/app/main.py:2887 ; orchestration.py:331-395
  @AC-2 @api
  Scénario: Un arrangement équilibré ne renvoie aucune alerte
    Quand j'envoie POST "/api/analyze/surcharge-registre" avec le corps JSON :
      """
      {"notes_simultanees": [["contrebasse",40],["violoncelle",52],
                             ["alto",60],["violon",67]]}
      """
    Alors la réponse a le statut 200
    Et la liste "avertissements" est vide

  # réf: lyra-api/analysis/AnalysisController.java:182 ; lyra-ml/app/main.py:2887 ; SEUIL_REGISTRE_GRAVE_MIDI = 48 (orchestration.py:297), resserré ≤ 12 demi-tons
  @AC-3 @api
  Scénario: Trois notes graves resserrées produisent « boue du grave » nommant les instruments, sans refus
    Quand j'envoie POST "/api/analyze/surcharge-registre" avec le corps JSON :
      """
      {"notes_simultanees": [["contrebasse",36],["violoncelle",40],["tuba",43]]}
      """
    Alors la réponse a le statut 200
    Et un élément de "avertissements" a "type_avertissement" égal à "boue_du_grave"
    Et cet avertissement a "instruments_en_cause" égal à ["contrebasse", "violoncelle", "tuba"]

  # réf: lyra-api/analysis/AnalysisController.java:182 ; lyra-ml/app/main.py:2887 ; SEUIL_TROU_SEMITONES = 24 (orchestration.py:307)
  @AC-4 @api
  Scénario: Deux registres séparés de plus de deux octaves sans note médiane produisent « trou de tessiture »
    Quand j'envoie POST "/api/analyze/surcharge-registre" avec le corps JSON :
      """
      {"notes_simultanees": [["tuba",40],["flûte",84]]}
      """
    Alors la réponse a le statut 200
    Et un élément de "avertissements" a "type_avertissement" égal à "trou_de_tessiture"

  # réf: lyra-api/analysis/AnalysisController.java:182 ; lyra-ml/app/main.py:2887 ; orchestration.py:344
  @AC-5 @api
  Scénario: Une liste de notes simultanées vide est rejetée
    Quand j'envoie POST "/api/analyze/surcharge-registre" avec le corps JSON :
      """
      {"notes_simultanees": []}
      """
    # RÉSOLU (code + exécution) : routes hors qualité-mélodique/composition — lyra-ml 422/500 n'est PAS traduit par lyra-api (RestClientResponseException sans handler) et sort en 500 ; le brouillon supposait 502. L'oracle « refusée » reste 4xx ou 502 : un 500 est donc rapporté comme échec (voir rapport).
    Alors la requête est refusée
