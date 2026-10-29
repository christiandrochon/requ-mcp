# language: fr
@US-201 @REQ-201 @api
Fonctionnalité: Compter les syllabes en français et en anglais, en mode chanson (US-201)
  # REQ-201 - critères couverts à ce niveau : AC-2, AC-5, AC-6, AC-7

  Contexte:
    Soit l'API Lyra joignable

  @AC-2 @api
  Scénario: Vers anglais : syllabes et accent lexical par mot
    Quand j'envoie POST "/api/lyrics/analyze" avec le corps JSON "{\"texte\": \"Hello darkness my old friend\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 200
    Et le champ "vers[0].nombre_syllabes" est supérieur à 0
    Et le champ "vers[0].accents_lexicaux" est un objet
    Et le champ "vers[0].accents_lexicaux.Hello" est présent

  # RÉSOLU (code) : durees_notes et temps_forts sont alignés sur les MOTS du vers (syllables.py:494), pas sur les notes ; l'alerte exige un e chanté (durée > seuil) ET un temps fort.
  @AC-5 @api
  Scénario: Mode chanson : e muet compté sur note tenue, ignoré sous le seuil, alerte sur temps fort
    Quand j'envoie POST "/api/lyrics/comptage-mode-chanson" avec le corps JSON "{\"vers\": \"une rose\"}"
    Alors la réponse a le statut 200
    Et le champ "nombre_syllabes" vaut 2
    Quand j'envoie POST "/api/lyrics/comptage-mode-chanson" avec le corps JSON "{\"vers\": \"une rose\", \"durees_notes\": [1, 2.0], \"seuil_note_tenue_temps\": 1.0, \"temps_forts\": [false, false]}"
    Alors le champ "nombre_syllabes" vaut 3
    Et la liste "alertes" est vide
    Quand j'envoie POST "/api/lyrics/comptage-mode-chanson" avec le corps JSON "{\"vers\": \"une rose\", \"durees_notes\": [1, 0.5], \"seuil_note_tenue_temps\": 1.0, \"temps_forts\": [false, false]}"
    Alors le champ "nombre_syllabes" vaut 2
    Quand j'envoie POST "/api/lyrics/comptage-mode-chanson" avec le corps JSON "{\"vers\": \"une rose\", \"durees_notes\": [1, 2.0], \"seuil_note_tenue_temps\": 1.0, \"temps_forts\": [false, true]}"
    Alors la liste "alertes" n'est pas vide

  # Un refus d'entrée invalide en 500 (relayé en 502) est un défaut du code : on exige une erreur 4xx.
  @AC-6 @api
  Scénario: Mode chanson : listes de longueur incohérente refusées
    Quand j'envoie POST "/api/lyrics/comptage-mode-chanson" avec le corps JSON "{\"vers\": \"une rose\", \"durees_notes\": [1], \"temps_forts\": [false, false]}"
    Alors la requête est refusée par une erreur 4xx
    Et la réponse porte un message d'erreur non vide

  # RÉSOLU (code) : LyricsAnalysisRequest n'a pas de champ « variante » ; un mot absent du dictionnaire est estimé (pas d'erreur).
  @AC-7 @api
  Scénario: Mot anglais absent du dictionnaire : estimation heuristique sans erreur
    Quand j'envoie POST "/api/lyrics/analyze" avec le corps JSON "{\"texte\": \"The flibbertigibbet sings\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 200
    Et le champ "vers[0].nombre_syllabes" est supérieur à 0
