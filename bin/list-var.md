## GroqBash - Variabili canoniche

---

**name**: "_"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2411  
**kind**: "special"  
**declaration** null  
**occurrences**: 347, 512, 640, 884, 1300, 1338, 1373, 1430, 1545, 1620, 1690, 2909, 2938, 4406

---

**name**: "ALLOWED_MODELS"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 4070    
**kind**: "paramexp"  
**declaration**:
```sh
ALLOWED_MODELS="${ALLOWED_MODELS:-}"
if [ -f "$MODELS_FILE" ] && [ -s "$MODELS_FILE" ]; then
  # Normalize entries: strip leading "models/" and trim whitespace
  # Keep one model per line in ALLOWED_MODELS
  ALLOWED_MODELS="$(awk '{ gsub(/^models\//,""); sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$/,""); if (NF) print }' "$MODELS_FILE" 2>/dev/null || true)"
fi
```
**occurrences**: 3194, 3195, 3208, 4067, 4070, 4071, 4373, 4399, 4556, 4557, 4559, 4561

---

**name**: "B64_DECODE_OPT"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 1119    
**kind**: "literal"  
**declaration**:
```sh
# Default conservative options
B64_WRAP_OPT=""
B64_DECODE_OPT="-d"

# Detect encode option that prevents line wrapping (GNU coreutils)
if printf '' | base64 -w0 >/dev/null 2>&1; then
  B64_WRAP_OPT="-w0"
else
  B64_WRAP_OPT=""
fi

# Detect decode option (-d vs -D) and prefer the working one
if printf 'dGVzdA==' | base64 -d 2>/dev/null | grep -q 'test'; then
  B64_DECODE_OPT="-d"
elif printf 'dGVzdA==' | base64 -D 2>/dev/null | grep -q 'test'; then
  B64_DECODE_OPT="-D"
else
  B64_DECODE_OPT="-d"
fi
```
**occurrences**: 373, 374, 1119, 1130, 1132, 1134, 1137, 1412, 2936

---

**name**: "B64_WRAP_OPT"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 1118    
**kind**: "literal"  
**declaration**:
```sh
# Default conservative options
B64_WRAP_OPT=""
B64_DECODE_OPT="-d"

# Detect encode option that prevents line wrapping (GNU coreutils)
if printf '' | base64 -w0 >/dev/null 2>&1; then
  B64_WRAP_OPT="-w0"
else
  B64_WRAP_OPT=""
fi
```
**occurrences**: 364, 365, 502, 503, 1118, 1123, 1125, 1137, 1366, 1367, 1422, 1423

---

**name**: "BATCH_FILE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2083  
**kind**: "paramexp"  
**declaration**
```sh
BATCH_FILE="${BATCH_FILE:-}"
```
**occurrences**: 2083, 3608, 3629, 4548, 4569, 4639

---

**name**: "BUILD_MESSAGES_FILE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 4598  
**kind**: "literal"  
**declaration**
```sh
BUILD_MESSAGES_FILE="${RUN_TMPDIR%/}/session-${SESSION_ID}-messages.json"
```
**occurrences**: 2182, 2214, 2237, 2238, 2258, 2259, 2260, 2264, 4598, 4599, 4603, 4606, 4610, 4613, 4614, 4615, 4619, 4620, 4624, 4655, 4676, 4680, 4682, 4685, 4688, 4702, 4723, 4727, 4729, 4732, 4735, 4820, 4841, 4845, 4847, 4850, 4853

---

**name**: "CANONICAL_EXTRAS_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 208  
**kind**: "literal"  
**declaration**
```sh
CANONICAL_EXTRAS_DIR="${GROQBASH_DIR%/}/extras"
```
**occurrences**: 208, 212

---

**name**: "CHAT_MODE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2084  
**kind**: "paramexp"  
**declaration**
```sh
CHAT_MODE="${CHAT_MODE:-0}"
```
**occurrences**: 2084, 3608, 3667, 3748, 4548, 4644

---

**name**: "CONTENT"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2076  
**kind**: "paramexp"  
**declaration**
```sh
CONTENT="${CONTENT:-}"
```
**occurrences**: 2076, 2167, 2168, 2182, 2215, 2241, 2242, 2243, 4468, 4471, 4474, 4477, 4484, 4486, 4488, 4497, 4501, 4505, 4511, 4514, 4519, 4527, 4533, 4536, 4539, 4540, 4541, 4548, 4572, 4615, 4620, 4653, 4760, 4766, 4768, 4771, 4813, 4815, 4875, 4881, 4883, 4886, 4914, 4920, 4922, 4925

---

**name**: "CONVERSATION"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 4647  
**kind**: "literal"  
**declaration**
```sh
CONVERSATION=""
```
**occurrences**: 4647, 4652

---

**name**: "DEBUG"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 412  
**kind**: "literal"  
**declaration**
```sh
DEBUG="${GROQBASH_DEBUG}"
```
**occurrences**: 176, 184, 409, 410, 411, 412, 414, 417, 418, 425, 443, 445, 518, 596, 597, 797, 807, 816, 821, 837, 923, 1342, 1432, 1663, 1664, 1673, 1692, 1693, 1762, 1763, 1825, 1864, 1877, 1967, 2097, 2132, 2263, 2285, 2286, 2299, 2303, 2344, 2345, 2415, 2416, 2456, 2502, 2505, 2525, 2531, 2535, 2540, 2553, 2554, 2580, 2632, 2633, 2689, 2693, 2751, 2757, 2761, 2766, 2781, 2799, 2863, 2872, 2895, 2942, 2943, 3056, 3064, 3240, 3241, 3263, 3405, 3436, 3459, 3478, 3610, 3654, 3715, 3720, 3736, 4261, 4283, 4371, 4742, 4753, 4860

---

**name**: "DEST_BASE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 3928  
**kind**: "literal"  
**declaration**
```sh
DEST_BASE="$(cd "${GROQBASH_EXTRAS_DIR%/}" >/dev/null 2>&1 && pwd || printf '%s' "${GROQBASH_EXTRAS_DIR%/}")"
```
**occurrences**: 3928, 3929, 3930, 3931, 3937, 3939, 3955, 3960, 3964, 3965, 3985, 3994, 4016

---

**name**: "DEST_PROV"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 3931  
**kind**: "literal"  
**declaration**
```sh
DEST_PROV="${PROVIDERS_DIR:-${DEST_BASE:-$(canonical_config_dir)}/providers}"
```
**occurrences**: 3931, 3964, 4036

---

**name**: "DRY_RUN"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2099  
**kind**: "paramexp"  
**declaration**
```sh
DRY_RUN="${DRY_RUN:-0}"
```
**occurrences**: 169, 174, 175, 177, 2099, 2132, 2343, 2359, 2579, 3239, 3262, 3404, 3610, 3659, 3748, 3754, 3755, 4372, 4741, 4776, 4777, 4859, 4891, 4892

---

**name**: "ERRF"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 740    
**kind**: "paramexp"  
**declaration**:
```sh
# Canonical default (ensure_run_tmpdir): set ERRF to a per-run err.log if unset
: "${ERRF:=$RUN_TMPDIR/err.log}"

# In specific code paths (e.g., preparing curl temporary files) ERRF may be set
# to a more specific filename for that operation:
resp_tmp="${RUN_TMPDIR%/}/resp.json"
ERRF="${RUN_TMPDIR%/}/curl.err"
: > "$ERRF" 2>/dev/null || true
```
**occurrences**: 724, 740, 744, 745, 746, 781, 783, 787, 788, 836, 1190, 1197, 1198, 1199, 2073, 2114, 2330, 2411, 2412, 2442, 2444, 2454, 2457, 2458, 2460, 2546, 2558, 2573, 2628, 2629, 2640, 2641, 2658, 2666, 2674, 2692, 2694, 2695, 2697, 2773, 2785

---

**name**: "FINAL_MODEL"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 3866  
**kind**: "literal"  
**declaration**
```sh
FINAL_MODEL="$candidate"
```
**occurrences**: 3096, 3108, 3112, 3150, 3161, 3174, 3188, 3202, 3213, 3866, 4447, 4449, 4450, 4454, 4455, 4459

---

**name**: "GROQ_API_KEY"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2157  
**kind**: "paramexp"  
**declaration**
```sh
GROQ_API_KEY="${GROQ_API_KEY:-}"
```
**occurrences**: 106, 122, 123, 154, 155, 342, 2157, 2160, 2357, 2359, 2360, 2436, 2437, 2591, 2593, 2594, 2658, 2817, 2819, 2820, 2861, 3754, 3755

---

**name**: "GROQBASH_API_KEY"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: "paramexp"  
**declaration**:
```sh
# Provided by the environment as an alternative API key for GROQ requests.
# Not explicitly assigned in groqbash; used as a fallback when GROQ_API_KEY is unset.
# Example usage when building curl headers:
#   if [ -n "${GROQ_API_KEY:-}" ]; then
#     CURL_CMD_ARR+=( -H "Authorization: Bearer ${GROQ_API_KEY}" )
#   elif [ -n "${GROQBASH_API_KEY:-}" ]; then
#     CURL_CMD_ARR+=( -H "Authorization: Bearer ${GROQBASH_API_KEY}" )
#   fi
#
# If you want an explicit declaration in the repository, a conservative canonical form is:
#   GROQBASH_API_KEY="${GROQBASH_API_KEY:-}"
```
**occurrences**: 2359, 2360, 2438, 2439, 2593, 2594, 2658

---

**name**: "GROQBASH_API_URL"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 299, 304, 305

---

**name**: "GROQBASH_CONFIG_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 221  
**kind**: "paramexp"  
**declaration**
```sh
GROQBASH_CONFIG_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}"
```
**occurrences**: 75, 96, 221, 229, 230, 231, 232, 239, 240, 241, 245, 246, 251, 254, 255, 258, 337, 897, 905, 906, 1947, 1984, 2111, 3183, 3184, 3424, 3930, 4050, 4381

---

**name**: "GROQBASH_DEBUG"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 409, 411, 412

---

**name**: "GROQBASH_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 202  
**kind**: "literal"  
**declaration**
```sh
GROQBASH_DIR="${GROQBASH_ROOT%/}/groqbash.d"
```
**occurrences**: 96, 198, 199, 200, 202, 204, 208, 220, 221, 222, 223, 224, 225, 232, 241, 995, 1984

---

**name**: "GROQBASH_ERR_API"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 30  
**kind**: "literal"  
**declaration**
```sh
GROQBASH_ERR_API=16
```
**occurrences**: 30, 38

---

**name**: "GROQBASH_ERR_BAD_MODEL"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 25  
**kind**: "literal"  
**declaration**
```sh
GROQBASH_ERR_BAD_MODEL=11
```
**occurrences**: 25, 33

---

**name**: "GROQBASH_ERR_CURL_FAILED"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 26  
**kind**: "literal"  
**declaration**
```sh
GROQBASH_ERR_CURL_FAILED=12
```
**occurrences**: 26, 34

---

**name**: "GROQBASH_ERR_INVALID_JSON"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 27  
**kind**: "literal"  
**declaration**
```sh
GROQBASH_ERR_INVALID_JSON=13
```
**occurrences**: 27, 35

---

**name**: "GROQBASH_ERR_NO_API_KEY"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 24  
**kind**: "literal"  
**declaration**
```sh
GROQBASH_ERR_NO_API_KEY=10
```
**occurrences**: 24, 32

---

**name**: "GROQBASH_ERR_NO_PROMPT"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 28  
**kind**: "literal"  
**declaration**
```sh
GROQBASH_ERR_NO_PROMPT=14
```
**occurrences**: 28, 36

---

**name**: "GROQBASH_ERR_TMP"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 29  
**kind**: "literal"  
**declaration**
```sh
GROQBASH_ERR_TMP=15
```
**occurrences**: 29, 37

---

**name**: "GROQBASH_EXTRAS_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 212  
**kind**: "literal"  
**declaration**
```sh
GROQBASH_EXTRAS_DIR="${CANONICAL_EXTRAS_DIR}"
```
**occurrences**: 212, 213, 215, 218, 992, 995, 3689, 3704, 3763, 3928, 4381

---

**name**: "GROQBASH_HISTORY_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 224  
**kind**: "paramexp"  
**declaration**
```sh
GROQBASH_HISTORY_DIR="${GROQBASH_HISTORY_DIR:-$GROQBASH_DIR/history}"
```
**occurrences**: 224, 983, 985, 987, 992, 995, 1012, 1228, 1308, 1311, 1312, 1314, 1318, 1645, 1772, 1773, 3383, 4369, 4381, 4581, 4582, 4661, 4662, 4708, 4709, 4826, 4827

---

**name**: "GROQBASH_LOCK_TIMEOUT_HISTORY"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 1018  
**kind**: "paramexp"  
**declaration**
```sh
GROQBASH_LOCK_TIMEOUT_HISTORY="${GROQBASH_LOCK_TIMEOUT_HISTORY:-10}"
```
**occurrences**: 1018, 1227, 1320, 1340, 1843

---

**name**: "GROQBASH_LOCK_TIMEOUT_MODELS"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 1017  
**kind**: "paramexp"  
**declaration**
```sh
GROQBASH_LOCK_TIMEOUT_MODELS="${GROQBASH_LOCK_TIMEOUT_MODELS:-10}"
```
**occurrences**: 1017, 1358, 1379

---

**name**: "GROQBASH_LOCK_TIMEOUT_TMP"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 1016  
**kind**: "paramexp"  
**declaration**
```sh
GROQBASH_LOCK_TIMEOUT_TMP="${GROQBASH_LOCK_TIMEOUT_TMP:-10}"
```
**occurrences**: 1016, 1535

---

**name**: "GROQBASH_LOG"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 419  
**kind**: "paramexp"  
**declaration**
```sh
GROQBASH_LOG="${GROQBASH_LOG:-}" # optional path to append structured logs
```
**occurrences**: 417, 419, 428, 434, 440

---

**name**: "GROQBASH_MODELS_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 222  
**kind**: "paramexp"  
**declaration**
```sh
GROQBASH_MODELS_DIR="${GROQBASH_MODELS_DIR:-$GROQBASH_DIR/models}"
```
**occurrences**: 222, 226, 992, 995, 1011, 1982, 3045, 4367, 4381

---

**name**: "GROQBASH_PROVIDER_URL"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 299, 305, 306, 309, 317, 318, 324, 325, 2365, 2366, 2370, 2372, 2611, 2612, 2616, 2618, 2831, 2834, 2836, 2843, 2845, 4261

---

**name**: "GROQBASH_TEMPLATES_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 223  
**kind**: "paramexp"  
**declaration**
```sh
GROQBASH_TEMPLATES_DIR="${GROQBASH_TEMPLATES_DIR:-$GROQBASH_DIR/templates}"
```
**occurrences**: 223, 992, 995, 4491

---

**name**: "GROQBASH_TMPDIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 225  
**kind**: "paramexp"  
**declaration**
```sh
GROQBASH_TMPDIR="${GROQBASH_TMPDIR:-$GROQBASH_DIR/tmp}"
```
**occurrences**: 225, 717, 755, 756, 759, 760, 762, 763, 768, 791, 792, 793, 814, 822, 850, 984, 985, 992, 995, 1013, 1391, 1534, 1545, 1554, 1562, 1564, 1571, 1573, 1575, 1576, 1647, 1808, 1818, 1831, 1840, 1953, 1982, 2122, 4368, 4381, 4419, 4437

---

**name**: "GROQBASHERRAPI"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 38  
**kind**: "literal"  
**declaration**
```sh
GROQBASHERRAPI=$GROQBASH_ERR_API
```
**occurrences**: 38, 2851, 2856, 2867, 2876, 2899, 2915, 3229, 3254, 3276, 3443, 3454, 3462, 3476, 3481, 3491, 4295, 4299, 4308, 4929

---

**name**: "GROQBASHERRBAD_MODEL"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 33  
**kind**: "literal"  
**declaration**
```sh
GROQBASHERRBAD_MODEL=$GROQBASH_ERR_BAD_MODEL
```
**occurrences**: 33, 4444, 4451, 4456, 4562

---

**name**: "GROQBASHERRCURL_FAILED"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 34  
**kind**: "literal"  
**declaration**
```sh
GROQBASHERRCURL_FAILED=$GROQBASH_ERR_CURL_FAILED
```
**occurrences**: 34, 2352, 2587, 3474, 4802

---

**name**: "GROQBASHERRNO_PROMPT"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 36  
**kind**: "literal"  
**declaration**
```sh
GROQBASHERRNO_PROMPT=$GROQBASH_ERR_NO_PROMPT
```
**occurrences**: 36, 4545, 4550

---

**name**: "GROQBASHERRNOAPIKEY"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 32  
**kind**: "literal"  
**declaration**
```sh
GROQBASHERRNOAPIKEY=$GROQBASH_ERR_NO_API_KEY
```
**occurrences**: 32, 131, 138, 150, 2361, 2595, 2821, 4306

---

**name**: "GROQBASHERRTMP"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 37  
**kind**: "literal"  
**declaration**
```sh
GROQBASHERRTMP=$GROQBASH_ERR_TMP
```
**occurrences**: 37, 265, 568, 574, 585, 589, 617, 621, 630, 757, 866, 869, 877, 998, 1000, 1315, 1522, 1524, 1534, 1559, 1568, 1601, 2123, 2185, 2275, 2282, 2332, 2396, 2575, 2643, 2824, 2827, 2828, 2928, 2938, 3358, 3388, 3502, 3637, 3693, 3756, 3874, 3880, 3882, 3901, 3911, 3940, 3947, 3951, 3957, 3960, 3964, 3979, 3980, 3982, 3996, 3999, 4001, 4121, 4127, 4140, 4172, 4196, 4203, 4209, 4220, 4256, 4438, 4553, 4554, 4578, 4597, 4645, 4659, 4675, 4706, 4722, 4748, 4824, 4840, 4866

---

**name**: "HISTORY_LOCK"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 1012  
**kind**: "paramexp"  
**declaration**
```sh
HISTORY_LOCK="${HISTORY_LOCK:-$GROQBASH_HISTORY_DIR/history.lock}"
```
**occurrences**: 1012, 1222, 1233, 1319

---

**name**: "JSON_INPUT"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2077  
**kind**: "paramexp"  
**declaration**
```sh
JSON_INPUT="${JSON_INPUT:-}"
```
**occurrences**: 2077, 2167, 2182, 2212, 2219, 2220, 2221, 2226, 3608, 3627, 4461, 4463, 4471, 4534, 4548

---

**name**: "LEGACY_EXTRAS_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 209  
**kind**: "literal"  
**declaration**
```sh
LEGACY_EXTRAS_DIR="${SCRIPTDIR%/}/extras"
```
**occurrences**: 209, 3935, 3936

---

**name**: "LEGACY_REAL"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 3936  
**kind**: "literal"  
**declaration**
```sh
LEGACY_REAL="$(cd "${LEGACY_EXTRAS_DIR}" >/dev/null 2>&1 && pwd || printf '%s' "${LEGACY_EXTRAS_DIR}")"
```
**occurrences**: 3936, 3937, 3938

---

**name**: "LIST_MODELS"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2087  
**kind**: "paramexp"  
**declaration**
```sh
LIST_MODELS="${LIST_MODELS:-0}"
```
**occurrences**: 2087, 3609, 3620, 3748, 3873

---

**name**: "LIST_PROVIDERS"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 3609  
**kind**: "literal"  
**declaration**
```sh
LIST_MODELS="${LIST_MODELS:-0}" LIST_PROVIDERS="${LIST_PROVIDERS:-0}" FORCE_SAVE_MODE="${FORCE_SAVE_MODE:-}" OUT_PATH="${OUT_PATH:-}"
```
**occurrences**: 3609, 3621, 3748, 3821

---

**name**: "MAX_MODELS"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 227  
**kind**: "paramexp"  
**declaration**
```sh
MAX_MODELS="${MAX_MODELS:-200}"
```
**occurrences**: 227, 2861, 2910, 2944, 3017, 3178, 3206, 3562

---

**name**: "MAX_RETRIES"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2103  
**kind**: "paramexp"  
**declaration**
```sh
MAX_RETRIES="${MAX_RETRIES:-3}"
```
**occurrences**: 2103, 3402, 3490

---

**name**: "MAX_TOKENS"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2094  
**kind**: "paramexp"  
**declaration**
```sh
MAX_TOKENS="${MAX_TOKENS:-4096}"
```
**occurrences**: 2094, 2182, 2206, 2207, 2208, 2270, 3653, 4059, 4554

---

**name**: "MESSAGES_JSON"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 2182, 2213, 2233, 2234, 2249

---

**name**: "MODEL"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2095  
**kind**: "paramexp"  
**declaration**
```sh
MODEL="${MODEL:-}"
```
**occurrences**: 2095, 2182, 2258, 2259, 2262, 2264, 2270, 3095, 3098, 3099, 3100, 3104, 3111, 3112, 3182, 3184, 3625, 4057, 4347, 4398, 4399, 4443, 4450, 4455, 4459, 4557, 4558, 4560, 4784, 4817, 4897

---

**name**: "MODEL_PROVIDER_CFG"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 3860  
**kind**: "literal"  
**declaration**
```sh
MODEL_PROVIDER_CFG="$(canonical_model_file "${active_provider}")"
```
**occurrences**: 3140, 3145, 3146, 3860, 3861, 3862, 4359, 4360, 4361

---

**name**: "MODELS_FILE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 226  
**kind**: "paramexp"  
**declaration**
```sh
MODELS_FILE="${MODELS_FILE:-$GROQBASH_MODELS_DIR/models.txt}"
```
**occurrences**: 226, 2809, 2814, 2919, 2920, 2921, 2924, 2938, 2940, 2944, 2955, 2956, 2960, 2968, 2969, 2971, 2975, 2983, 3003, 3007, 3045, 3166, 3167, 3179, 3545, 3547, 3563, 3568, 3576, 3577, 3579, 3583, 3591, 3798, 3799, 3809, 4068, 4071, 4131, 4132, 4224, 4225, 4308, 4314, 4319

---

**name**: "MODELS_LOCK"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 1011  
**kind**: "paramexp"  
**declaration**
```sh
MODELS_LOCK="${MODELS_LOCK:-$GROQBASH_MODELS_DIR/models.lock}"
```
**occurrences**: 1011, 2931

---

**name**: "OUT_PATH"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2089  
**kind**: "paramexp"  
**declaration**
```sh
OUT_PATH="${OUT_PATH:-}"
```
**occurrences**: 2089, 3381, 3382, 3609, 3657

---

**name**: "OUTPUT_MODE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2101  
**kind**: "paramexp"  
**declaration**
```sh
OUTPUT_MODE="${OUTPUT_MODE:-text}"
```
**occurrences**: 2101, 3439, 3466, 3470, 3613, 3663, 3664, 3665, 3666, 3909, 4060, 4649, 4808

---

**name**: "PAYLOAD"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 582, 724, 738, 746, 779, 836, 2073, 2114, 2166, 2249, 2254, 2264, 2273, 2280, 2288, 2289, 2300, 2304, 2313, 2316, 2329, 2335, 2337, 2346, 2380, 2400, 2572, 2581, 2598, 2600, 3242, 3264, 3406

---

**name**: "PRINT_MODEL_FILE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 4336, 4337, 4338

---

**name**: "PROVIDER"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2105  
**kind**: "paramexp"  
**declaration**
```sh
PROVIDER="${PROVIDER:-groq}"
```
**occurrences**: 302, 1035, 1090, 1094, 2105, 2150, 2368, 2614, 2833, 2840, 2842, 3025, 3046, 3050, 3057, 3065, 3071, 3077, 3087, 3102, 3117, 3123, 3125, 3129, 3135, 3137, 3222, 3228, 3247, 3253, 3269, 3275, 3795, 3837, 3843, 3845, 3849, 3855, 3857, 3887, 3893, 3895, 4111, 4118, 4119, 4121, 4126, 4130, 4140, 4151, 4196, 4198, 4202, 4208, 4213, 4218, 4219, 4223, 4231, 4238, 4251, 4254, 4255, 4260, 4261, 4276, 4284, 4294, 4298, 4304, 4305, 4315, 4316, 4346, 4354, 4356, 4390, 4391, 4406, 4408, 4455, 4528, 4627, 4692, 4743, 4746, 4817, 4861, 4864

---

**name**: "PROVIDER_CLI"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 3611  
**kind**: "paramexp"  
**declaration**
```sh
PROVIDER_CLI="${PROVIDER_CLI:-}" PROVIDER_INTERACTIVE="${PROVIDER_INTERACTIVE:-0}"
```
**occurrences**: 3117, 3118, 3119, 3129, 3130, 3131, 3611, 3671, 3794, 3795, 3837, 3838, 3839, 3849, 3850, 3851, 3885, 3888, 3889, 4108, 4115, 4117, 4119, 4121, 4136, 4137, 4146

---

**name**: "PROVIDER_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 1032, 1034, 1035, 1038, 1045

---

**name**: "PROVIDER_INTERACTIVE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 3611  
**kind**: "literal"  
**declaration**
```sh
PROVIDER_CLI="${PROVIDER_CLI:-}" PROVIDER_INTERACTIVE="${PROVIDER_INTERACTIVE:-0}"
```
**occurrences**: 3611, 3671, 3748, 4108, 4146

---

**name**: "PROVIDER_MODULE_PATH"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 4036  
**kind**: "literal"  
**declaration**
```sh
PROVIDER_MODULE_PATH="${DEST_PROV}/${p}.sh"
```
**occurrences**: 1031, 1048, 1059, 1064, 1067, 1075, 1077, 1078, 1086, 1104, 4036, 4037, 4038

---

**name**: "PROVIDERS_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 215  
**kind**: "paramexp"  
**declaration**
```sh
PROVIDERS_DIR="${PROVIDERS_DIR:-${GROQBASH_EXTRAS_DIR%/}/providers}"
```
**occurrences**: 215, 217, 218, 1031, 1032, 3762, 3763, 3824, 3929, 3931, 4096

---

**name**: "PWD"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 1228, 1645, 1647

---

**name**: "QUIET"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2098  
**kind**: "paramexp"  
**declaration**
```sh
QUIET="${QUIET:-0}"
```
**occurrences**: 182, 183, 185, 2098, 3610, 3660, 3748, 4370, 4646, 4649, 4808

---

**name**: "RANDOM"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 501, 625, 873, 1312, 1540, 1584, 1593, 1672, 1789, 1831

---

**name**: "RESP"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 657, 660, 662, 664, 669, 680, 713, 724, 739, 742, 743, 746, 780, 783, 785, 786, 836, 2073, 2114, 2119, 2329, 2374, 2382, 2395, 2403, 2506, 2514, 2515, 2516, 2518, 2520, 2522, 2523, 2524, 2526, 2529, 2530, 2532, 2536, 2538, 2539, 2541, 2544, 2548, 2553, 2555, 2560, 2572, 2606, 2620, 2738, 2741, 2742, 2743, 2745, 2748, 2749, 2750, 2752, 2755, 2756, 2758, 2762, 2764, 2765, 2767, 2770, 2775, 2780, 2782, 2787, 2793, 2794, 3284, 3286, 3293, 3295, 3306, 3356, 3357, 3362, 3363, 3425, 3427, 3428, 3433, 3434, 3460, 3479, 4754, 4775, 4776, 4777, 4891, 4892

---

**name**: "RUN_TMPDIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 280, 281, 282, 450, 481, 482, 718, 724, 725, 735, 736, 737, 738, 739, 740, 746, 749, 769, 775, 776, 779, 780, 781, 793, 808, 812, 813, 815, 817, 822, 836, 838, 841, 848, 849, 851, 908, 1610, 1614, 1631, 1647, 1808, 1818, 1831, 1840, 1953, 2073, 2114, 2119, 2122, 2186, 2329, 2374, 2382, 2390, 2395, 2403, 2410, 2411, 2516, 2572, 2606, 2620, 2624, 2625, 2626, 2627, 2628, 2638, 2724, 2727, 2729, 2734, 2739, 2743, 2826, 3386, 3387, 4437, 4493, 4596, 4598, 4676, 4723, 4841

---

**name**: "SCRIPT_DATE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 19  
**kind**: "literal"  
**declaration**
```sh
SCRIPT_DATE="2026-05-07"
```
**occurrences**: 19, 3687, 4345

---

**name**: "SCRIPT_NAME"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 17  
**kind**: "literal"  
**declaration**
```sh
SCRIPT_NAME="groqbash"
```
**occurrences**: 17, 421, 3687

---

**name**: "SCRIPT_VERSION"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 18  
**kind**: "literal"  
**declaration**
```sh
SCRIPT_VERSION="2.0.0"
```
**occurrences**: 18, 3687, 4345

---

**name**: "SCRIPTDIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 196  
**kind**: "literal"  
**declaration**
```sh
SCRIPTDIR="$(resolve_script_dir)"
```
**occurrences**: 196, 198, 204, 209, 1005, 3915, 3919, 3934

---

**name**: "SE_ENGINE_PATH"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 3704  
**kind**: "literal"  
**declaration**
```sh
SE_ENGINE_PATH="${GROQBASH_EXTRAS_DIR%/}/session/session-engine.sh"
```
**occurrences**: 3704, 3706, 3709, 3710

---

**name**: "SESSION_CACHE_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 1984  
**kind**: "literal"  
**declaration**
```sh
SESSION_CACHE_DIR="${GROQBASH_CONFIG_DIR:-$GROQBASH_DIR/config}/session_cache"
```
**occurrences**: 1984, 1985, 1986, 2013, 2036, 2058, 2061

---

**name**: "SESSION_DIR"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 987  
**kind**: "literal"  
**declaration**
```sh
SESSION_DIR="${GROQBASH_HISTORY_DIR%/}/sessions"
```
**occurrences**: 987, 988, 989, 1772, 1773

---

**name**: "SESSION_ID"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2079  
**kind**: "paramexp"  
**declaration**
```sh
SESSION_ID="${SESSION_ID:-}"
```
**occurrences**: 2079, 3632, 3633, 3735, 4575, 4576, 4577, 4598, 4603, 4606, 4610, 4656, 4657, 4658, 4676, 4680, 4682, 4685, 4703, 4704, 4705, 4723, 4727, 4729, 4732, 4758, 4766, 4768, 4771, 4787, 4789, 4792, 4821, 4822, 4823, 4841, 4845, 4847, 4850, 4872, 4873, 4881, 4883, 4886, 4900, 4902, 4905, 4913, 4920, 4922, 4925

---

**name**: "SESSION_WINDOW"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2080  
**kind**: "paramexp"  
**declaration**
```sh
SESSION_WINDOW="${SESSION_WINDOW:-}"
```
**occurrences**: 2080, 3641, 3642, 3646, 4585, 4586, 4587, 4590, 4592, 4593, 4603, 4606, 4610, 4664, 4665, 4666, 4669, 4671, 4672, 4680, 4682, 4685, 4711, 4712, 4713, 4716, 4718, 4719, 4727, 4729, 4732, 4829, 4830, 4831, 4834, 4836, 4837, 4845, 4847, 4850

---

**name**: "SET_DEFAULT_MODEL"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2085  
**kind**: "paramexp"  
**declaration**
```sh
SET_DEFAULT_MODEL="${SET_DEFAULT_MODEL:-}"
```
**occurrences**: 2085, 3608, 3624, 3877, 3900, 3905

---

**name**: "SRC_BASE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 3917  
**kind**: "literal"  
**declaration**
```sh
SRC_BASE="${INSTALL_EXTRAS_SRC%/}"
```
**occurrences**: 3917, 3919, 3923, 3924, 3926, 3937, 3945, 3946, 3949, 3950, 3955, 3956, 3959, 3960, 3969, 3972, 3993

---

**name**: "STDIN_CONTENT"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 4462  
**kind**: "literal"  
**declaration**
```sh
STDIN_CONTENT=""
```
**occurrences**: 4462, 4464, 4485, 4486, 4510, 4511

---

**name**: "STREAM_MODE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2100  
**kind**: "paramexp"  
**declaration**
```sh
STREAM_MODE="${STREAM_MODE:-0}"
```
**occurrences**: 2100, 2169, 2182, 2189, 3610, 3661, 3662, 3748, 3909, 4632, 4693, 4700

---

**name**: "SUPPORTED_PROVIDERS"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2104  
**kind**: "paramexp"  
**declaration**
```sh
SUPPORTED_PROVIDERS="${SUPPORTED_PROVIDERS:-groq gemini huggingface}"
```
**occurrences**: 2104, 3776, 4105, 4116, 4148

---

**name**: "TEMPERATURE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2092  
**kind**: "paramexp"  
**declaration**
```sh
TEMPERATURE="${TEMPERATURE:-${TURE:-1.0}}"
```
**occurrences**: 2091, 2092, 2093, 4058

---

**name**: "TEMPLATE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2082  
**kind**: "paramexp"  
**declaration**
```sh
TEMPLATE="${TEMPLATE:-}"
```
**occurrences**: 2082, 3608, 3628, 4482, 4491

---

**name**: "THRESHOLD"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2102  
**kind**: "paramexp"  
**declaration**
```sh
THRESHOLD="${THRESHOLD:-1000}"
```
**occurrences**: 2102, 3376, 3658, 4061

---

**name**: "TMP_LOCK"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 1013  
**kind**: "paramexp"  
**declaration**:
```sh
TMP_LOCK="${TMP_LOCK:-$GROQBASH_TMPDIR/tmp.lock}"
```
**occurrences**: 1013, 1529, 1533

---

**name**: "TURE"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: 2091  
**kind**: "paramexp"  
**declaration**
```sh
TURE="${TURE:-${TEMPERATURE:-1.0}}"
```
**occurrences**: 2091, 2092, 2093, 2182, 2202, 2203, 2204, 2270, 3651, 3652, 4058, 4553

---

**name**: "VALID_MESSAGES_JSON"  
**type**: "string"  
**source**: "groqbash"  
**declaration_line**: null    
**kind**: null  
**declaration**: null  
**occurrences**: 2183, 2217, 2223, 2228, 2233, 2234, 2237, 2238, 2242, 2243, 2247, 2248, 2253, 2254, 2255, 2271

---
