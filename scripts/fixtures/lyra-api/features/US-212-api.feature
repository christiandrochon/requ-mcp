# language: fr
@US-212 @REQ-212 @api
Fonctionnalité: Aider le chanteur à prononcer des paroles anglaises (US-212)
  # REQ-212 - critères couverts à ce niveau : AC-4, AC-5, AC-6
  # RÉSOLU (code) : seule la route /api/lyrics/prononciation/phrase existe (PhraseRequest : texte, langue) ; pas de paramètre « accent » ni de champ « piège P4 » => ces parties de l'AC sont NON TESTÉES (écart spec/code à arbitrer).

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api
  Scénario: Vers avec /θ/ : IPA affichée
    Quand j'envoie POST "/api/lyrics/prononciation/phrase" avec le corps JSON "{\"texte\": \"Think about this\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 200
    Et le champ "ipa" contient "θ"

  @AC-5 @api
  Scénario: Mot hors lexique : transcription eSpeak-NG avec avertissement
    Quand j'envoie POST "/api/lyrics/prononciation/phrase" avec le corps JSON "{\"texte\": \"zorblax\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 200
    Et le champ "mots[0].ipa" est non vide
    Et la liste "avertissements" n'est pas vide

  @AC-6 @api
  Scénario: Demande invalide refusée (champ texte manquant)
    Quand j'envoie POST "/api/lyrics/prononciation/phrase" avec le corps JSON "{\"langue\": \"anglais\"}"
    Alors la réponse a le statut 422

  @AC-6 @api
  Scénario: Demande invalide refusée (texte vide)
    Quand j'envoie POST "/api/lyrics/prononciation/phrase" avec le corps JSON "{\"texte\": \"\", \"langue\": \"anglais\"}"
    Alors la requête est refusée par une erreur 4xx
