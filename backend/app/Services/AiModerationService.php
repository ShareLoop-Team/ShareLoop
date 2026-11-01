<?php

namespace App\Services;

class AiModerationService
{
    protected array $toxicKeywords = [
        'scam', 'fraud', 'steal', 'idiot', 'stupid', 'bastard', 'fake',
        'threat', 'kill', 'hate', 'harass', 'vulgar', 'abuse',
    ];

    protected array $scamKeywords = [
        'advance payment', 'wire transfer', 'western union', 'crypto',
        'bank transfer before delivery', 'send money', 'whatsapp me for payment',
        'courier fee', 'processing charge', 'refundable deposit',
    ];

    protected array $spamKeywords = [
        'casino', 'betting', 'viagra', 'earn money fast', 'click here',
        'work from home 100k', 'free gift card', 'lottery winner',
    ];

    /**
     * Inspect text content and return scores and flags.
     */
    public function scan(string $title, string $description): array
    {
        $content = strtolower($title . ' ' . $description);

        $toxicityMatches = $this->findMatches($content, $this->toxicKeywords);
        $scamMatches = $this->findMatches($content, $this->scamKeywords);
        $spamMatches = $this->findMatches($content, $this->spamKeywords);

        $toxicityScore = min(100, count($toxicityMatches) * 35);
        $scamScore = min(100, count($scamMatches) * 45);
        $spamScore = min(100, count($spamMatches) * 30);

        // Overall risk determination
        $isFlagged = ($toxicityScore >= 40) || ($scamScore >= 40) || ($spamScore >= 50);

        $reasons = [];
        if (! empty($toxicityMatches)) {
            $reasons[] = 'Potential toxic language: ' . implode(', ', array_unique($toxicityMatches));
        }
        if (! empty($scamMatches)) {
            $reasons[] = 'Suspicious payment/advance fee language: ' . implode(', ', array_unique($scamMatches));
        }
        if (! empty($spamMatches)) {
            $reasons[] = 'Potential promotional/spam phrases: ' . implode(', ', array_unique($spamMatches));
        }

        return [
            'is_flagged' => $isFlagged,
            'toxicity_score' => $toxicityScore,
            'scam_score' => $scamScore,
            'spam_score' => $spamScore,
            'risk_level' => $isFlagged ? ($scamScore >= 80 || $toxicityScore >= 70 ? 'high' : 'medium') : 'low',
            'matched_reasons' => $reasons,
        ];
    }

    protected function findMatches(string $content, array $keywords): array
    {
        $matches = [];
        foreach ($keywords as $keyword) {
            if (str_contains($content, $keyword)) {
                $matches[] = $keyword;
            }
        }

        return $matches;
    }
}
