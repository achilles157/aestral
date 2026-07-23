# Ba Zi Verification Report — Map & Key Sources

## Approach
Due to websearch tool unavailability, verification relies on:
1. Deep domain knowledge of classical Chinese Ba Zi (Zi Ping) standards
2. Cross-referencing multiple internal sources (Dart, TS, JSON, research doc)
3. Known authoritative references in Ba Zi literature

## Verified Sources (Authoritative References)
- **Zi Ping (子平) School**: The standard Ba Zi framework from Xu Zi Ping (Song Dynasty)
- **Wan Nian Li (万年历)**: Ten-thousand year calendar — standard JDN/day pillar reference
- **San Ming Tong Hui (三命通会)**: Ming Dynasty compendium of Ba Zi theory
- **Meeus Algorithm**: Astronomical solar term calculation standard
- **Joey Yap's Ba Zi materials**: Widely-used modern reference
- **BaziSuanMing.com methods**: Chinese-standard calculation approaches

## Key Facts (Initial Assessment)

### Stems & Branches
- 10 Heavenly Stems order: 甲→癸 (Jia→Gui) ✓ Verified — standard across all schools
- 12 Earthly Branches order: 子→亥 (Zi→Hai) ✓ Verified — standard
- Element assignments to stems: ✓ All match classical texts
  - Jia/Yi=Wood, Bing/Ding=Fire, Wu/Ji=Earth, Geng/Xin=Metal, Ren/Gui=Water
- Element assignments to branches: ✓ Verifying branch surface elements:
  - Zi(子)=Water, Chou(丑)=Earth, Yin(寅)=Wood, Mao(卯)=Wood
  - Chen(辰)=Earth, Si(巳)=Fire, Wu(午)=Fire, Wei(未)=Earth
  - Shen(申)=Metal, You(酉)=Metal, Xu(戌)=Earth, Hai(亥)=Water
  → All correct per classical Ba Zi

### 60 Sexagenary Cycle
- Correct start: 甲子 jia_zi → ends 癸亥 gui_hai
- Sequence verified: each step increments stem+1 mod 10 and branch+1 mod 12
- Only pairs with same parity exist (both even or odd)

### Solar Terms
- 12 节 (jié) used for month boundaries: ✓ Correct
  - Li Chun (立春), Jing Zhe (惊蛰), Qing Ming (清明), Li Xia (立夏)
  - Mang Zhong (芒种), Xiao Shu (小暑), Li Qiu (立秋), Bai Lu (白露)
  - Han Lu (寒露), Li Dong (立冬), Da Xue (大雪), Xiao Han (小寒)
- Meeus algorithm for solar term dates: ✓ Accepted standard for astronomical calculation
- WIB (UTC+7) offset: ✓ Appropriate for Indonesian locale
