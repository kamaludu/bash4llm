#### 9.2.2 Mappatura della Labeling Function e Predicati sulle Transizioni

La mappa $L(S)$ determina l'appartenenza dei simboli in $AP$ mediante le proiezioni dello stato $S$ e la transazione candidata in valutazione contesto $t_{\text{prop}}$ , mentre i predicati di concorrenza e transizione sono formalizzati sulle coppie di stati adiacenti $(S_i, S_{i+1})$ :

1. **SafetyGateAllowed:** 
```math
\text{SafetyGateAllowed} \in L(S) \iff \mathcal{R}_{\text{exec}}(S, t_{\text{prop}}) = \text{ALLOW}
```

2. **DecisionOutcomeAllowed:** $\text{DecisionOutcomeAllowed} \in L(S) \iff \text{Derive}(\pi_{\text{persistent}}(S), \pi_{\text{internal}}(S)).\mathcal{O}_{\text{decision}} = \text{ALLOW}$.
3. **HashChainValid:** 
```math
\text{HashChainValid} \in L(S) \iff H(\text{Canon}(t_{\text{prev}})) = \pi_{\text{internal}}(S).\text{last\_hash}
```

4. **MonotonicFence (Predicato su Transizione):** 
```math
\text{MonotonicFence}(S_i, S_{i+1}) \iff \pi_{\text{internal}}(S_{i+1}).\mathcal{F}_{\text{lease}}.\text{fencing}_{\text{token}} > \pi_{\text{internal}}(S_i).\mathcal{F}_{\text{lease}}.\text{fencing}_{\text{token}}
```

5. **StateIsRecoverableFailure:** 
```math
\text{StateIsRecoverableFailure} \in L(S) \iff \pi_Q(S) = \text{RECOVERABLE\_FAILURE}
```

6. **StateIsSecurityLockdown:** 
```math
\text{StateIsSecurityLockdown} \in L(S) \iff \pi_Q(S) = \text{SECURITY\_LOCKDOWN}
```

7. **StateIsValidationError:** 
```math
\text{StateIsValidationError} \in L(S) \iff \pi_Q(S) = \text{VALIDATION\_ERROR}
```

8. **StateIsNormal:** $\text{StateIsNormal} \in L(S) \iff \pi_Q(S) = \text{NORMAL}$.
9. **StateIsReadOnly:** 
```math
\text{StateIsReadOnly} \in L(S) \iff \pi_Q(S) = \text{SAFE\_READ\_ONLY\_MODE}
```

10. **JourneyProgressive:** $\text{JourneyProgressive} \in L(S) \iff \pi_Q(S) \in F_{\text{oper}} \land \pi_{Q_H}(S) \in \{h_1, h_2, h_3, h_4, h_5, h_6, h_{11}\}$.
11. **KeyIsShredded:** 
```math
\text{KeyIsShredded}_c \in L(S) \iff \text{LookupKey}(K_c) = \bot
```

12. **UserEngaged:** 
```math
\text{UserEngaged} \in L(S) \iff \pi_{Q_H}(S) \notin \{h_7, h_{10}\}
```

13. **NonTerminalHumanState:** 
```math
\text{NonTerminalHumanState} \in L(S) \iff \pi_{Q_H}(S) \notin F_H
```

14. **HumanState:** 
```math
\text{HumanState}_{h_i} \in L(S) \iff \pi_{Q_H}(S) = h_i
```

15. **CryptoShredExecuted (RFC-005):**
```math
\text{CryptoShredExecuted}_c \in L(S) \iff t.\text{event} = \text{EV\_CRYPTO\_SHRED\_EXECUTED}(c)
```

#### 9.2.3 Formule Temporali First-Order LTL (FO-LTL)
La dinamica di sicurezza del modello è specificata dalle seguenti formule First-Order LTL:

* **FO-LTL Safety 1 (Safety Gate / Policy Guidance Corrected):**

```math
\square \left( \text{DecisionOutcomeAllowed} \implies \text{SafetyGateAllowed} \right)
```

* **FO-LTL Safety 2 (Fencing e Lease Recovery):**

```math
\square \left( \neg \text{MonotonicFence}(S_i, S_{i+1}) \implies X(\text{StateIsRecoverableFailure}) \right)
```

* **FO-LTL Safety 3 (Hash Chain Integrity):**

```math
\square \left( \neg \text{HashChainValid} \implies X(\text{StateIsSecurityLockdown}) \right)
```

* **FO-LTL Liveness 4 (Recuperabilità del Progresso dopo Errore Tecnico):**

```math
\square \left( (\text{StateIsValidationError} \lor \text{StateIsRecoverableFailure}) \implies \diamondsuit \text{JourneyProgressive} \right)
```

* **FO-LTL Safety 5 (Invarianza dell'Oblio Crittografico / RFC-005):**

```math
\forall c \in \mathcal{I}_{\text{case}}, \quad \square \left( \text{CryptoShredExecuted}_c \implies X(\square \text{KeyIsShredded}_c) \right)
```

#### 9.2.4 Riduzione e Mapping verso LTL Proposizionale per Model Checkers
Per l'esecuzione diretta su strumenti di Model Checking Simbolico (NuSMV, SPIN, TLC), la quantificazione del primo ordine viene ridotta allo spazio discreto delle proposizioni atomiche mediante istanziazione finita sui domini $\mathcal{I}_{\text{case}}$:

```math
\text{Lowering}_{\text{LTL}}(\forall c \in \mathcal{I}_{\text{case}}, \phi(c)) := \bigwedge_{i=1}^{|\mathcal{I}_{\text{case}}|} \phi(c_i)
```

#### 9.2.5 Proprietà CTL (Computation Tree Logic)

* **CTL System Agency Guarantee (Accessibilità del Progresso di Sistema):**

```math
AG \left( \text{UserEngaged} \implies EF (\text{JourneyProgressive}) \right)
```

* **CTL Trap-Free Safety (Recuperabilità dal Lockdown):**

```math
AG \left( \text{StateIsSecurityLockdown} \implies EF (\text{StateIsNormal} \lor \text{StateIsReadOnly}) \right)
```

* **CTL Non-Terminal Successor Guarantee (Presenza di Transizioni Abilitate):**

```math
AG \left( \text{NonTerminalHumanState} \implies EX(\text{True}) \right)
```

---
