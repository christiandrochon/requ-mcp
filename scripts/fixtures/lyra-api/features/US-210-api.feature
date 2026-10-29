# language: fr
@US-210 @REQ-210 @api
Fonctionnalité: Corriger la grammaire de paroles anglaises en contexte (étage 1) (US-210)
  # REQ-210 - critères couverts à ce niveau : AC-4, AC-5, AC-6
  # RÉSOLU (code) : GrammaireExceptionHandler rend l'entrée invalide en 422 {code: "entree_invalide", message}.

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api @requiert-languagetool
  Scénario: « She don't know. » : faute d'accord HE_VERB_AGR
    Soit LanguageTool et Harper démarrés
    Quand j'envoie POST "/api/lyrics/grammaire/analyses" avec le corps JSON "{\"texte\": \"She don't know.\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 200
    Et la liste "alertes" contient un élément dont "regle_id" vaut "HE_VERB_AGR"

  @AC-5 @api @requiert-languagetool
  Scénario: Harper indisponible : LanguageTool seul
    Soit LanguageTool démarré et Harper arrêté
    Quand j'envoie POST "/api/lyrics/grammaire/analyses" avec le corps JSON "{\"texte\": \"She don't know.\", \"langue\": \"anglais\"}"
    Alors la liste "avertissements" contient un élément dont "code" vaut "harper_indisponible"

  @AC-6 @api
  Scénario: Texte vide refusé
    Quand j'envoie POST "/api/lyrics/grammaire/analyses" avec le corps JSON "{\"texte\": \"\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 422

  @AC-6 @api
  Scénario: Texte de plus de 200 vers refusé
    Quand j'envoie POST "/api/lyrics/grammaire/analyses" avec le corps JSON "{\"texte\": \"@vers:201\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 422

  @AC-6 @api
  Scénario: Texte de plus de 20 000 caractères refusé
    Quand j'envoie POST "/api/lyrics/grammaire/analyses" avec le corps JSON "{\"texte\": \"@caracteres:20001\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 422
