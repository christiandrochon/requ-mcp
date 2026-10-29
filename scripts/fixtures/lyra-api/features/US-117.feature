# language: fr
@api @US-117 @REQ-117
Fonctionnalité: Accompagnement générique sommaire à tout moment de la composition

  Contexte:
    Soit l'API Lyra joignable
    Et une progression d'accords générée (4 mesures, "Do" "ionien", graine 9)

  # réf: lyra-api/generation/GenerationController.java:84 ; lyra-ml/app/main.py:1049 ; basse racine groove.py:816
  @AC-3 @api
  Scénario: Pour une progression fournie : basse sur la fondamentale de chaque accord et coups de batterie
    Quand j'envoie POST "/api/generate/groove" avec "tempo_bpm" 100, "nombre_mesures" 4 et les "accords" de la progression
    Alors la réponse a le statut 200
    Et les "root_note" de "basse" valent les "root_note" des accords de la progression
    Et la liste "batterie" n'est pas vide

  # réf: lyra-api/generation/GenerationController.java:84 ; lyra-ml/app/main.py:1049 ; groove.py:915-929
  @AC-4 @api
  Scénario: La réponse porte l'indicateur générique et l'avertissement de repère jetable
    Quand j'envoie POST "/api/generate/groove" avec le corps JSON :
      """
      {"tempo_bpm": 100, "nombre_mesures": 2}
      """
    Alors la réponse a le statut 200
    Et le champ "est_generique" vaut true
    # RÉSOLU : comparaison insensible aux accents (étape « contient »).
    Et un élément de "avertissements" contient "jetable"
    Et un élément de "avertissements" contient "pas une section rythmique definitive"
