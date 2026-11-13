# UI 设计规范

> 依据用户提供的双屏参考图提取。  
> 本文只描述**视觉风格**与**版面布局**，不涉及功能逻辑与交互流程。  
> 参考图尺寸 439 × 454 px，双手机并排；本文以 393 × 852 pt 的手机竖屏为落地基准换算，数值为**设计建议值**。  
> 标注说明：`实测` = 从图中取色/量取；`估算` = 按比例换算；`推断` = 图中未出现、按同一视觉语言补齐。

---

## 一、视觉风格

### 1.1 色彩系统

#### 主色与角色分配

| 角色 | 色值 | 使用位置 | 依据 |
|---|---|---|---|
| Primary / 主色 | `#6E8BFF` | 主按钮、选中步骤点、选中图标、重点卡片底色 | 实测（按钮与课程卡大面积取色） |
| Primary Deep / 主色深 | `#5A74F0` | 主按钮按压态、深色渐变端 | 推断 |
| Primary Light / 主色浅 | `#AFC0FF` | 进度线、浅色描边、次级点缀 | 实测近似 |
| Primary Tint / 主色淡底 | `#DFE5FF` | 题面底、输入框底、选中项底色 | 实测（223,229,255） |
| Primary Wash / 更浅底 | `#EEF3FF` | 分组背景、列表悬停、浅色标签 | 推断 |

主色是**唯一的高饱和行动色**。一屏只允许一个主色实心 CTA；其余按钮用白色、浅紫底或纯文字。

#### 中性色阶

| 角色 | 色值 | 使用位置 |
|---|---|---|
| Ink / 主文字 | `#1D2340` | 标题、正文重点、导航选中图标 |
| Ink Secondary / 次文字 | `#7F88A4` | 说明文、未选中图标、次级信息 |
| Ink Muted / 弱文字 | `#A0A8C0` | 占位符、辅助说明、禁用态 |
| Line / 描边 | `#DCE5FB` | 输入框、标签、次级按钮描边 |
| Divider / 分隔 | `#E8EEFB` | 列表分隔、卡片内分隔 |
| Surface / 卡面 | `#FFFFFF` | 内容大卡、底部导航、输入框 |
| Surface Tint / 卡面淡底 | `#F7F9FF` | 次级卡、输入框静态底 |

#### 背景层次

从下到上共 4 层，靠**明度与透明度**分层，不靠重描边：

1. **页面底层**：对角线性渐变，顶部 `#D5DDFB` → 底部 `#B9C6F4`（实测范围 `#C5D4FF` 至 `#AFBAF1`，角度约 165°）。
2. **内容浮层**：白色大圆角面板，顶部圆角 28–32，带极轻投影，覆盖在渐变背景上。
3. **卡片层**：纯白或 92% 白，圆角 20–24，投影更弱。
4. **控件层**：浅紫底、白底、主色实心；标签与输入框允许 1 px 描边。

参考图中首页与练习页都采用「渐变背景 + 白色大面板」的骨架，因此**背景永远不要用纯白铺满整屏**。

#### 辅助色

| 角色 | 色值 | 使用规则 |
|---|---|---|
| Pink / 玫粉 | `#F27CC5` | 第二张课程卡、强调标签；只做整卡底色，不做小字 |
| Yellow / 奶黄 | `#FFD35C` | 插画高光、成就标记、少量标签 |
| Mint / 薄荷 | `#9FE3C5` | 第三类卡片、正向反馈底色 |
| Orange / 杏橙 | `#FFB07A` | 插画暖色、提醒点 |
| Success | `#3CCB9A` | 连接成功、完成勾选（推断） |
| Warning | `#FFB45C` | 需注意但非错误（推断） |
| Error | `#FF6B7A` | 校验失败、删除（推断） |

辅助色**一屏最多出现两种**，且不能与主色争夺同一视觉层级。正文、标题、图标不要使用辅助色。

---

### 1.2 字体与字号层级

参考图使用几何感、字腔较圆的无衬线字体（接近 Poppins / Plus Jakarta Sans / Nunito Sans），中文使用同风格圆润黑体。**实测**：标题字重明显为 700，正文 400–500，按钮 600。

| Token | 字号 / 行高 | 字重 | 字距 | 使用 |
|---|---|---|---|---|
| Display | 28 / 34 | 700 | -0.6 | 首页问候、复盘主标题 |
| H1 | 24 / 30 | 700 | -0.4 | 页面标题、场景名 |
| H2 | 20 / 26 | 700 | -0.3 | 卡片大标题 |
| Section | 16 / 22 | 700 | -0.1 | 分区标题（Featured courses 级） |
| Card Title | 15 / 21 | 700 | -0.1 | 课程卡、场景卡标题 |
| Body | 14 / 22 | 500 | 0 | 对话正文、说明 |
| Body Secondary | 13 / 20 | 400 | 0 | 二级说明、卡片描述 |
| Caption | 11 / 16 | 500 | 0.1 | 时间、来源、辅助信息 |
| Tag | 10 / 14 | 600 | 0.2 | 标签、步骤、状态 |
| Button | 14 / 20 | 600 | 0.1 | 主/次按钮 |
| Nav Label | 10 / 12 | 500 | 0.1 | 底部导航文字（参考图仅图标） |

规则：

- 标题与正文的字号差至少 6 pt，字重差至少 200。
- 一屏最多出现 3 个层级：标题、正文、说明。
- 英文标题避免全大写；标签可全大写，但字距 +0.2。
- 数值类信息（时长、价格、回合数）用 600–700 字重，允许 13–15 pt。

---

### 1.3 圆角、描边与阴影

#### 圆角

| Token | 半径 | 使用 |
|---|---|---|
| Radius XL | 32 | 白色内容大面板顶部、底部 Sheet |
| Radius LG | 24 | 主卡片、场景卡、复盘卡 |
| Radius MD | 18–20 | 横向课程卡、对话气泡容器 |
| Radius SM | 12–14 | 卡内题面块、输入框、分组块 |
| Radius XS | 8–10 | 标签、答案块、步骤点容器 |
| Radius Pill | 999 | 主按钮、次按钮、搜索框、底部导航、筛选 Chip |

参考图的卡片几乎全部是「大圆角 + 无描边」；小控件才用描边。**不要给所有元素统一加边框**。

#### 描边

- 仅用于：输入框、答案/选项标签、次级按钮、虚线「添加」占位。
- 宽度 1 px，颜色 `#DCE5FB`；选中态为 `#6E8BFF`，宽度 1.5 px 或加 3–4 px 浅色外环。
- 主色实心卡与白色大面板**不加描边**。

#### 阴影

| 层级 | 建议值 | 使用 |
|---|---|---|
| Shadow Card | `0 8 24 rgba(78,102,190,0.10)` | 主卡片、课程卡 |
| Shadow Floating | `0 16 40 rgba(70,92,180,0.18)` | 底部导航、悬浮条 |
| Shadow Primary | `0 10 24 rgba(110,139,255,0.28)` | 主按钮 |
| Shadow Sheet | `0 -16 40 rgba(70,90,165,0.14)` | 底部 Sheet |

阴影颜色必须带蓝紫调，不能使用纯黑；模糊值大、透明度低，避免「卡片浮在灰底上」的脏感。

---

### 1.4 图标风格

- 线性图标，描边 1.8–2 px，圆头圆角端点。
- 常用尺寸 20 / 24；放在 40–44 的圆形浅底按钮中。
- 默认颜色 `#7F88A4`，选中/强调为 `#6E8BFF`，放在主色底上为白色。
- 同一屏图标风格统一，不混用实心与线性；仅「收藏/勾选」等状态图标允许实心。
- 图标留白充足，图标与文字间距 6–8。

#### 图片与插画

- 参考图的核心图像语言是**3D 黏土/果冻质感的小物件**：书本、闹钟、灯泡、纸飞机、铃铛、笑脸。
- 处理方式：高饱和但柔和的渐变色、圆润体积、软阴影、无描边、背景透明；以 1–3 个物件为一组，**叠放在彩色卡片的右上或右下，允许被卡片边缘裁切**。
- 物件不承担信息功能，只负责情绪与层次；不要用写实照片、扁平线性插画或图标堆叠替代。
- 头像：圆角方形（12）48 × 48，右上角 7–8 px 状态点，白色 2 px 描边。
- 不用大面积背景图；不用带文字的插画。

> 若项目无法产出 3D 素材，退化为「同色系渐变几何块 + 单个线性图标」，仍保持「右下叠放、允许裁切」的构图，不要退回纯色图标。

---

### 1.5 控件形态

#### 按钮

| 类型 | 规格 |
|---|---|
| Primary | 高 50–52，全圆角，`#6E8BFF` 底，白字 600 14–15，带主色阴影；左右内边距 24 |
| Secondary | 高 48–50，白底，1 px `#DCE5FB` 描边，`#46527A` 字 600 |
| Text | 13–14，`#6E8BFF` 字 600，右侧 12–14 的 chevron |
| Icon Button | 40–44 圆形，浅底或透明；图标 20 |

主按钮在参考图中是「一条通栏胶囊」，左右各留 24 外边距，距底部安全区 16–20。

#### 卡片

- 主卡片：白底、24 圆角、18–20 内边距、极轻阴影。
- 课程卡（横向）：彩色底（主色/粉/薄荷）、18 圆角、16 内边距、白字；标题最多 2 行；右上角 3D 物件。
- 信息卡：白底，标题 15/700，正文 13/400，行距 20；卡内不再套第三层卡，改用浅紫底块分区。
- 列表卡：白底 20 圆角，单行 56–64 高，左图标 40、右 chevron；列表之间 10–12 间距。

#### 输入与搜索

- 搜索：全圆角，高 40–44，白底，左 18 放大镜，占位 `#A0A8C0`，右侧可放 40 圆形主色筛选按钮。
- 表单输入：12–14 圆角，高 44–48，白底，1 px `#DCE5FB`；聚焦时边框 `#6E8BFF` + 3 px 浅色外环。
- 不使用下划线式输入框；不使用灰色大面积底。

#### 标签 / Chip

- 高 24–28，左右 8–10，圆角 8，字号 10–11，字重 600。
- 浅色底 `#EEF3FF` + 主色字；彩色卡上使用 `rgba(255,255,255,0.18)` 底 + 白字。
- 可点 Chip 用白底 + `#DCE5FB` 描边；选中变主色实心或浅紫底 + 主色描边。
- 标签不换行，一行最多 2 个；超出用「+N」。

#### 进度

- 线性进度：轨道高 2–4，`#DCE5FB`，已完成 `#6E8BFF`，圆头。
- 分步进度：4 个 10 px 圆点 + 2 px 连接线；已完成实心主色，当前点白底主色描边，未完成白底浅色描边。
- 参考图只使用分步点，没有百分比数字；如需要百分比，用 12/600 主色字放在右侧。

#### 分段控件 / 开关（推断）

- 分段：整体浅紫底 999 圆角，内边距 3；选中项白底、圆角 999、字重 600、轻阴影。
- 开关：42 × 25，轨道 `#DCE5FB`，选中 `#6E8BFF`，白色 19 圆点。

#### 底部导航

- 悬浮白色胶囊：左右 20–24 边距，高 56–60，圆角 30，`Shadow Floating`。
- 4 个图标均分，图标 22–24，选中主色，未选中 `#7F88A4`；参考图无文字标签。
- 导航悬浮在内容之上，页面底部需预留 80–96 的滚动内边距，避免最后一项被遮挡。

---

## 二、版面布局

### 2.1 整体骨架

基准画布 **393 × 852**，单列竖屏，左右安全边距 **24**，内容宽 **345**。

```
┌─────────────────────────┐
│ 状态栏 44                │  渐变背景
│ 页面头部 56–72           │  头像/返回 + 标题
│ ┌─────────────────────┐ │
│ │ 白色内容面板         │ │  顶部圆角 32
│ │ 20–24 内边距          │ │
│ │ 搜索 / 标题 / 卡片    │ │
│ │ ...                  │ │  可滚动
│ └─────────────────────┘ │
│                         │
│ 悬浮底部导航 56          │  左右 24，距底 16
└─────────────────────────┘
```

练习/对话页则把「白色内容面板」替换为「白色大卡片 + 底部通栏 CTA」，但保持同一中轴与边距。

### 2.2 首页骨架（对应参考图左屏）

从上到下：

1. 状态栏：44 高，透明。
2. 问候区：左侧 48 圆角方头像 + 右侧两行文字；标题 22–24/700，副标题 13/400；左右 24。
3. 白色内容面板：距顶部约 16，顶部圆角 32，内边距 20；顶部中央 32 × 4 的浅色拖拽条（纯装饰）。
4. 搜索行：搜索框高 40–44，占满剩余宽度；右侧 40 圆形主色按钮，间距 10。
5. 分区标题行：左标题 16/700，右侧「View All」12/600 主色 + chevron；上下间距 20/12。
6. 横向课程卡：卡宽约 240–260（内容宽的 70–75%），高 120–132，间距 12，右侧露出下一张 24–32。
7. 次级分区（My Courses）：圆形徽章 56 + 12 文字标签，横向 4 个，间距 16。
8. 底部：悬浮导航 + 80 滚动留白。

首屏信息预算：**1 个问候 + 1 个搜索 + 1 个横向卡组 + 下一分区标题**；不堆叠超过 2 个完整纵向区块。

### 2.3 练习页骨架（对应参考图右屏）

1. 顶部导航行：左返回 40，中「Lesson 3/12」11–12/600 次文字，右占位 40，保证标题严格居中。
2. 标题块：居中；emoji/插画 24–28 + 标题 22–24/700，最多 2 行；副标题 13/400 次文字，间距 6–8。
3. 分步进度：4 点，宽约 160–180，居中，上下间距 16/20。
4. 白色内容面板：顶部圆角 32，内边距 20–24，覆盖屏幕下半部分；内部可滚动。
5. 面板内层级：小标题 16/700 → 说明 13/400 → 浅紫题面块（12 圆角、16 内边距）→ 答案 Chip 两行 → 主按钮。
6. 主按钮：面板底部通栏，距面板底 16–20；按钮上方留 20–24。

### 2.4 对齐与中轴

- 页面整体**单中轴**：左右 24 对称；标题、进度、插画、主按钮居中。
- 卡片内容左对齐，左基线 = 24 + 卡内边距（18–20）= 42–44。
- 分区标题与卡片左边缘对齐；「View All」贴右边缘。
- 顶部返回按钮与内容左边缘对齐；中间步骤文字严格居中，不因左右按钮宽度不同而偏移。
- 对话页：AI 消息左对齐、用户消息右对齐，气泡最大宽度 82–84%。
- 气泡操作行：朗读/重听贴气泡左内边缘，翻译贴右内边缘，中间用弹性空白分隔（最小间距 8）；两项不得上下叠放或同侧相邻，避免误触。

### 2.5 间距节奏

| 场景 | 间距 |
|---|---|
| 页面左右 | 24 |
| 状态栏 → 头部 | 8–12 |
| 头部 → 内容面板 | 16–20 |
| 面板内边距 | 20–24 |
| 分区之间 | 24–28 |
| 卡片之间（纵） | 12–16 |
| 卡片之间（横） | 12 |
| 卡片内边距 | 18–20 |
| 卡内块之间 | 12–16 |
| 标题 → 正文 | 6–8 |
| 标签之间 | 8–10 |
| 底部 CTA 距安全区 | 16–20 |

使用 **4/8 pt 网格**：4、8、12、16、20、24、32、40。不要出现 5、7、13 这类零散值。

### 2.6 卡片内部紧凑度与内容密度

- 信息密度偏低：每张卡 1 个标题 + 1 行说明 + 1 个元信息即可。
- 主卡标题最多 2 行；说明最多 2 行；超出用省略。
- 卡内不再嵌套完整卡片；需要分组时用浅紫底块或分隔线，避免「卡中卡中卡」。
- 首屏只展示 1–2 个视觉焦点；彩色卡与白色卡交替，形成节奏。
- 列表项高度 56–64；左右内边距 16；图标 40；信息两行（主 14/600，次 11/400）。

### 2.7 留白

- 白面板内部保留 20–24 四周留白；标题与内容之间 16–20。
- 大标题上方留白明显大于下方，形成「呼吸感」。
- 彩色卡内部文字只占左侧 55–60%，右侧 40% 留给 3D 插画。
- 底部导航上方必须有 24–32 的渐变过渡或留白，避免内容贴边。

### 2.8 首屏与滚动

- 首屏必须出现：头部身份/标题、搜索或主操作、第一组内容卡。
- 次屏内容从第二分区标题开始，滚动时不吸顶重头部；只允许底部导航悬浮。
- 滚动区底部内边距 ≥ 96，保证悬浮导航不遮内容。
- 长页面分区间距大于卡间距，靠留白而非分割线区分章节。

---

## 三、Flutter 落地规格

### 3.1 颜色 Token

```dart
class AppColors {
  // 主色
  static const primary = Color(0xFF6E8BFF);
  static const primaryDeep = Color(0xFF5A74F0);
  static const primaryLight = Color(0xFFAFC0FF);
  static const primaryTint = Color(0xFFDFE5FF);
  static const primaryWash = Color(0xFFEEF3FF);

  // 中性
  static const ink = Color(0xFF1D2340);
  static const inkSecondary = Color(0xFF7F88A4);
  static const inkMuted = Color(0xFFA0A8C0);
  static const line = Color(0xFFDCE5FB);
  static const divider = Color(0xFFE8EEFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFF7F9FF);

  // 辅助
  static const pink = Color(0xFFF27CC5);
  static const yellow = Color(0xFFFFD35C);
  static const mint = Color(0xFF9FE3C5);
  static const orange = Color(0xFFFFB07A);
  static const success = Color(0xFF3CCB9A);
  static const warning = Color(0xFFFFB45C);
  static const error = Color(0xFFFF6B7A);

  // 背景渐变
  static const bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD5DDFB), Color(0xFFB9C6F4)],
  );
}
```

### 3.2 字号 Token

```dart
class AppText {
  static const display = TextStyle(fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: AppColors.ink);
  static const h1 = TextStyle(fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink);
  static const h2 = TextStyle(fontSize: 20, height: 26 / 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.ink);
  static const section = TextStyle(fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w700, letterSpacing: -0.1, color: AppColors.ink);
  static const cardTitle = TextStyle(fontSize: 15, height: 21 / 15, fontWeight: FontWeight.w700, letterSpacing: -0.1, color: AppColors.ink);
  static const body = TextStyle(fontSize: 14, height: 22 / 14, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const bodySecondary = TextStyle(fontSize: 13, height: 20 / 13, fontWeight: FontWeight.w400, color: AppColors.inkSecondary);
  static const caption = TextStyle(fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: AppColors.inkMuted);
  static const tag = TextStyle(fontSize: 10, height: 14 / 10, fontWeight: FontWeight.w600, letterSpacing: 0.2);
  static const button = TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);
}
```

字体建议：`Poppins`（英文）+ `Noto Sans SC` / `HarmonyOS Sans SC`（中文）；若包体受限，用系统字体并保留上述字号/字重。

### 3.3 间距 / 圆角 / 阴影 Token

```dart
class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = 24.0;      // 左右页边距
  static const section = 28.0;   // 分区间距
  static const scrollBottom = 96.0;
}

class AppRadius {
  static const xl = 32.0;
  static const lg = 24.0;
  static const md = 18.0;
  static const sm = 12.0;
  static const xs = 8.0;
  static const pill = 999.0;
}

class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x1A4E66BE), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const floating = [
    BoxShadow(color: Color(0x2E465CB4), blurRadius: 40, offset: Offset(0, 16)),
  ];
  static const primary = [
    BoxShadow(color: Color(0x476E8BFF), blurRadius: 24, offset: Offset(0, 10)),
  ];
}
```

### 3.4 组件规格

#### 主按钮

- 高度 50；`BorderRadius.circular(999)`；背景 `AppColors.primary`；文字 `AppText.button.copyWith(color: Colors.white)`。
- 阴影 `AppShadows.primary`；禁用态背景 `AppColors.primaryTint`，文字 `AppColors.inkMuted`，无阴影。
- 通栏时左右各 24，距底部安全区 16。

#### 次按钮

- 高度 48；白底；1 px `AppColors.line` 描边；文字 `#46527A` 600 14；圆角 999。
- 与主按钮并排时等宽，间距 12。

#### 卡片

```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadows.card,
  ),
)
```

- 彩色课程卡：主色/粉色/薄荷底，18 圆角，16 内边距，白字；插画放右上，允许裁切。
- 信息卡：白底 24 圆角 20 内边距；卡内浅紫块用 12 圆角、16 内边距。

#### 输入框

- 高 48；圆角 14；白底；1 px `AppColors.line`；内边距左右 16；文字 14/500。
- 聚焦：边框 `AppColors.primary`，外环 `BoxShadow(color: Color(0x146E8BFF), blurRadius: 0, spreadRadius: 3)`。
- 搜索框：高 44，全圆角，左图标 18，右侧可放 40 圆形主色按钮。

#### 标签 / Chip

- 高 26；左右 10；圆角 8；字号 10–11/600。
- 普通：`AppColors.primaryWash` 底 + `AppColors.primary` 字。
- 彩色卡上：`Colors.white.withOpacity(0.18)` 底 + 白字。
- 可点：白底 + 1 px `AppColors.line`；选中：`primaryTint` + 1 px `primary`。

#### 进度

- 分步：圆点 10，间距 40–48；连线 2 px；已完成 `primary`，未完成白底 + 1.5 px `line`。
- 线性：高 3，圆角 2，轨道 `line`，进度 `primary`。

#### 底部导航

- 容器：左右 24，高 58，白底，圆角 30，`AppShadows.floating`。
- 4 项均分；图标 22；选中 `primary`，未选中 `inkSecondary`；无文字标签。
- 页面滚动底部留白 96。

#### 底部 Sheet

- 顶部圆角 32；白底；顶部 4 × 36 拖拽条 `line`；内容内边距 20–24；`AppShadows.sheet`。
- 与页面背景之间加 40% 黑紫遮罩，不用纯黑。

#### M4 新增组件规格（先改规范再落代码）

| 组件 | 规格 |
|---|---|
| 提示阶梯 Sheet | 复用 `AppBottomSheet`（32 圆角 / 遮罩 40%）；每个阶梯项白底或 `primaryWash`、12 圆角、内边距 12/10，图标 18，标题 14/600，说明 11/500，选中项右侧 16 主色勾选；底部只允许 1 个主色实心 CTA |
| 提示结果卡 | `primaryWash` 底、无阴影、24 圆角、内边距 14/12；标签 10/600 主色深，英文正文 14/500 行高 1.5，其下一行 11/500 `inkSecondary` 中文译文（前缀「译」），辅助说明 11/500 `inkMuted`；不出现第二个主色实心按钮 |
| 气泡操作行 | 气泡正文下方一行；「重听/停止」胶囊靠左、「中文/翻译中…」胶囊靠右，`Spacer` 分隔且最小间距 8；胶囊沿用 10/600 小按钮规格（白底 + 1px `divider`、`pill` 圆角、内边距 8/5），请求中文案置灰且不可点 |
| 翻译三态 | 对话页不设切换栏；三态（关闭 / 点按 / 常开）仅在设置页「翻译默认方式」选择，点按翻译沿用气泡操作行胶囊规格，不新增颜色或字号 |
| 纠错展开块 | `warning` 10% 底、12 圆角、12 内边距；原句/原因 11/500，改进句 14/500；「试听 / 删除」为 10/600 胶囊小按钮（白底 + 1px `divider`），间距 8 |
| 文章正文 | `##` 小标题用 `AppText.section`，正文 `AppText.body` 行高 1.7、段距 12；`[图：说明]` 用 `surfaceTint` 底、12 圆角、12 内边距、11/500 灰字占位，不下载图片 |
| 出处块 | `AppCard`（24 圆角 / 16 内边距）；标签列固定宽 64、11/500，值 13/400；原文链接 11/500 `primaryDeep` + 14 图标，整行可点 |
| 底部版权说明 | 固定在详情页底部白底，11/500 `inkMuted` 居中，包 `SafeArea`，不与悬浮导航同屏出现 |

新增组件一律只用既有 Token（主色 / primaryWash / surfaceTint / warning / line / divider）与 4/8 网格间距，不引入新色值、新字号或新阴影层级。

#### 场景库新增组件规格（先改规范再落代码）

| 组件 | 规格 |
|---|---|
| 场景库头部 | 复用 `PageScaffold`（32 圆角白面板），标题「场景库」；面板内首行一行 `AppText.caption` 说明「共 N 个场景」，下方 12 间距接搜索框；不新增彩色 Hero、不新增主色实心按钮 |
| 搜索行 | 复用 `AppTextField`（高 48、圆角 12、白底 1px `line`、左 18 放大镜），`prefixIcon: Icons.search_rounded`，占位 11–13/400 `inkMuted`；左右页边距 24；不加右侧筛选圆形按钮（分类 Chip 已承担筛选） |
| 分类 Chip 组 | 横向单行可滚动，高 28、pill 圆角、左右 12、间距 8；未选中白底 + 1px `line` + `inkSecondary` 11/500；选中 `primaryTint` 底 + 1px `primary` + `primaryDeep` 11/600；Chip 组上下间距 12 / 16；Chip 文案取场景数据的 `category`，首项固定「全部」 |
| 场景库列表卡 | 复用 `AppCard`（24 圆角、16 内边距、`AppShadows.card`），卡间距 12；左 46 × 46 圆角 14 图标块（分类浅底 + 24 分类图标），中间标题 `AppText.cardTitle` 一行省略、英文副标题 `AppText.caption` 一行省略、第三行元信息 `AppText.caption`（分类 · 级别 · 回合），右 `Icons.chevron_right_rounded` 20 `inkMuted`；整卡可点，跳场景详情 |
| 练过标签 | `AppTag`（10/600、`primaryWash` 底 + `primaryDeep` 字）放在标题行右侧，文案「练过 N 次」；只在该场景计数 > 0 时出现，不与级别标签同时超过 2 个 |
| 分类图标块 | 只用 Material 线性图标 + 既有辅助色浅底（`primaryWash` / `primaryTint` / `mint` 28% / `warning` 10% / `pink` 10% / `yellow` 20%）；强调色只用 `primaryDeep` / `orange` / `success` / `warning`；图标 24，不用 3D 插画的替代色块，不引入新色值 |
| 空态 | 复用 `EmptyState`（88 圆形 `primaryWash` + 38 图标 + H2 标题 + `bodySecondary` 说明），用于筛选/搜索无结果；文案说明如何清除筛选 |

场景库页沿用「一屏一个主色实心 CTA」约束：本页不设 CTA；分类 Chip 与卡片不使用第二种高饱和辅助色作为大面积底色，辅助色只出现在 46 × 46 图标块内。首页「场景练习」区块保持 1 张主推大卡 + 1 张紧凑卡，右侧文字按钮改为「全部 N 个」（`SectionTitle` 的 `actionLabel`，12/600 主色，N 由实际场景数据计算），不把所有场景卡堆进首屏。分类数量随数据增长，Chip 组仍保持横向单行滚动，不改为多行或新增组件。

#### 会话续练新增组件规格（先改规范再落代码）

| 组件 | 规格 |
|---|---|
| 首页「继续上次」续练卡 | 复用 `AppCard`（24 圆角、16 内边距、`AppShadows.card`），底色只用 `primaryWash`，不加描边、不加阴影层级；左 42 × 42 圆角 12 `mint` 28% 图标块 + `Icons.play_arrow_rounded` 24 `success`；中间 `AppText.cardTitle` 场景名 + `AppText.caption`「进行中 · N 轮 · 日期」两行；右 `AppTag(label: '继续练习', color: primaryDeep, background: surface, icon: play_arrow_rounded)`；整卡可点进 `/chat/:id`；不新增主色实心 CTA（首页已有「今日练习」渐变卡） |
| 记录页续练卡 | 在既有 `_HistoryCard` 结构上改：状态标签 '进行中' 用 `warning` 10% 底 + `warning` 字；第三行追加 `AppText.caption`「点按继续这段对话」，字色 `primaryDeep`、11–13/500；卡片整卡可点进 `/chat/:id`（已完成卡仍进 `/review/:id`）；不新增按钮、不新增第二行副标题之外的元素 |
| 场景详情续练入口 | `_StartBar` 在 `PrimaryButton` 上方增加一行 `SecondaryButton`（高 50、白底 1px `line`、字 `ink` 13–14），文案「继续上次（N 轮）」，图标 `Icons.play_arrow_rounded` 18；两按钮间距 8；有续练会话时主按钮文案改为「开始新练习」，没有时保持「开始练习」 |
| 对话页「已接上」提示条 | 复用对话页既有提示条规格（`AppCard` + `primaryWash` 底 + 15px `primaryDeep` 图标 + `AppText.caption`），右侧一个 `TextButton`「知道了」；文案「已接上上次的对话（N 轮），接着说就行」；出现位置在离线提示条之前，不自动消失，由用户点掉 |
| 对话页「补回复」提示条 | 同上规格但底色 `warning` 10%、图标 `Icons.reply_rounded` `warning`、右侧 `TextButton`「重试」；文案「上次这句还没等到 AI 回复，点重试接着聊」；用户点重试或发送新消息后消失；不自动发请求 |

续练不引入新色值、新字号、新圆角或新阴影层级；状态色沿用 `success` / `warning` / `primaryDeep`，文字沿用 `AppText.cardTitle` / `caption` / `tag`。

#### 对话交互体验新增组件规格（先改规范再落代码）

| 组件 | 规格 |
|---|---|
| 正向反馈动效 | 对话区右下角 190 × 150 的 `IgnorePointer` 浮层；20 个粒子沿圆周散开、带轻微重力与淡出，中心光晕用 `primary` 20% → 0，总时长 1100ms；鼓励徽章为白底 pill、`primaryTint` 1px 描边、`AppShadows.soft`、13 图标 + 10/700 `primaryDeep` 文案，缩放 0.78 → 1、后段淡出；不拦截点击、不加声音，粒子只取 `primary` / `primaryLight` / `yellow` / `mint` |
| 回答句操作栏 | 用户气泡外侧右对齐一行，顶部间距 5、右侧 4；3 枚 28 × 28 圆形图标按钮，间距 6，图标 14；默认白底 + 1px `divider` + `inkSecondary`，激活为 `primaryWash` 底 + `primaryTint` 描边 + `primaryDeep` 图标，无录音置灰到 `inkMuted` 55%，请求中显示 1.6 描边 `CircularProgressIndicator`；只用图标 + `Tooltip` / `Semantics`，不加文字标签 |
| 优化结果卡 | 紧接操作栏下方，`primaryWash` 底、`AppRadius.sm` 圆角、`primaryTint` 1px 描边、12/10 内边距、最大宽 300；标题 10/600 `primaryDeep`，原句 11/500 删除线 `inkMuted`，改进句 `AppText.body` 行高 1.5，理由 `AppText.caption`；底部「试听 / 存入表达本」复用 10/600 胶囊小按钮（白底 + 1px `divider`），不出现第二个主色实心 CTA |
| 内联提示面板 | 复用 `AppCard`（`primaryWash` 底、无阴影、12/10 内边距）；结果用 `AnimatedSize` 就地展开，白底 `AppRadius.sm` + `primaryTint` 描边，英文 `AppText.body` 行高 1.5 + 中文对照；英文句下方紧跟「朗读 / 停止」胶囊小按钮（与「试听 / 存入表达本」同款：白底 + 1px `divider` + 10/600 `primaryDeep` + 12 图标，播放态换 `stop` 图标与「停止」文案），只读英文原句、不复述中文；**不使用底部 Sheet / 弹窗**，不自动发送、不写入对话历史 |
| 自建场景管理入口 | 场景库列表卡标题行追加 `AppTag`（「自建」，`mint` 字色），右侧箭头前加 `more_horiz` 18 `inkMuted` 的弹出菜单（编辑 / 删除）；仅 `isBuiltin == false` 出现，内置场景保持只读；菜单不新增色值与圆角 |
| 自定义场景表单 | 复用 `PageScaffold` + `AppTextField` + 既有 `_ChoiceChip` 规格；底部固定「删除 / 保存」按钮行沿用主 / 次按钮规格（并排等宽、间距 10）；开场白预览卡为 `primaryWash` 底、无阴影、14/12 内边距 + 30 圆形试听按钮；不新增第三个主色 CTA |
| 表达本添加与空态 | 页头右侧「添加表达」为 `primaryWash` 底 pill + `primaryTint` 描边 + 11/700 `primaryDeep`；展开的表单复用 `AppCard` + `AppTextField` + 主 / 次按钮；空态复用 `EmptyState`，下方给 1 个主色实心 CTA 与 1 个次按钮，再列 3 条常用表达卡（`AppCard` 无阴影 + 30 圆形加号），不新增第二处主色实心按钮 |

本次新增组件仍只使用既有 Token 与 4/8 网格间距；动效不引入第三方动画库或资源文件。

#### 二期听写新增组件规格（先改规范再落代码）

| 组件 | 规格 |
|---|---|
| 首页「听写教材」栏目 | 与「方法 / 技巧」同构：`SectionTitle` + 单张 `AppCard`（24 圆角 / 16 内边距），左 42 × 42 圆角 12 `primaryWash` 图标块 + `Icons.hearing_outlined` 22 `primaryDeep`，中间 `AppText.cardTitle` 标题 + `AppText.caption` 副标题，右 `chevron_right_rounded`；不新增 Tab、不新增第二个主色实心 CTA |
| 教材卡 | 复用 `AppCard`（24 圆角 / 16 内边距 / `AppShadows.card`），卡间距 12；第一行 `AppText.cardTitle` 标题 + 右侧 `AppTag`（`primaryWash` 底 + `primaryDeep` 字）显示「N 句」；第二行 `AppText.caption` 元信息「时长 · 已练 X 句 · 正确率 Y%」；第三行 3 px 线性进度（轨道 `line`、进度 `primary`），只用 4/8 网格间距 |
| 句子行 | `AppCard` 内一行：左 28 宽序号 `AppText.caption`（`inkMuted`），中间最多 2 行 `AppText.bodySecondary`（英文），右侧 8 圆点状态点（未练 `inkMuted` / 已通过 `success` / 有错 `warning`）+ `AppText.caption` 时间轴；无描边、无第二层卡片；长按/菜单提供合并、拆分、微调，菜单沿用既有 10/600 胶囊小按钮规格 |
| 片段播放控制条 | 听写页唯一的主视觉：`AppCard`（`primaryWash` 底、无阴影、16 内边距）；上方一行 `AppText.caption`「第 07 / 62 句」+ 右侧词数弱提示；中间 44 圆形 `primary` 播放键（28 图标，白字）+ 左右各 32 圆形白底小键（0.75x / 复听），间距 12；下方 3 px 线性进度（`line` / `primary`）；不出现字幕原文、不出现视频画面 |
| 听写输入区 | 复用 `AppTextField`（高 48、圆角 14、白底 1px `line`），允许多行时最小高 88；底部一行 `PrimaryButton`（「提交这句」）与 `SecondaryButton`（「显示答案」）并排等宽、间距 12；判分前 `PrimaryButton` 是页面唯一主色实心 CTA |
| 逐词差异标签 | 结果卡内 `Wrap`，间距 6/4；每词一个 8 圆角胶囊、左右 8、上下 4、字号 11/600；正确 `mint` 28% 底 + `success` 字，漏写 `warning` 10% 底 + `warning` 字（词前加 `＋` 表示要补），多写 `error` 10% 底 + `error` 字（词前加 `−`），拼错 `primaryTint` 底 + `primaryDeep` 字（下方 10 字注释）；不使用下划线/表格/第二种高饱和底色 |
| 判分结果卡 | `AppCard`（24 圆角 / 16 内边距）；首行 `AppText.h2` 显示「正确率 92%」+ `AppTag`（通过 `success` / 未通过 `warning`）；第二行 `AppText.caption` 解释口径「正确词 11 / 参考词 12 · 阈值 90%」；下方逐词差异标签；再下方 10/600 胶囊小按钮「复听 / 存入表达本 / 下一句」；未通过时不显示整句答案，点「显示答案」后才展开 `AppText.body` 原句 |
| 错句本行 | 与句子行同构，左侧 8 圆点状态点、下方 `AppText.caption` 正确率与时间轴；顶部 `PrimaryButton`「只练全部错句」，按教材分组的 `SectionTitle` 带「练这份的错句」入口，沿用既有按钮规格，不新增颜色 |
| 导入页文件行 | `AppCard` 内左 36 × 36 圆角 10 `surfaceTint` 图标块 + `Icons.insert_drive_file_outlined` 18 `inkSecondary`，中间 `AppText.body` 文件名 + `AppText.caption` 状态，右 `Icons.check_circle_rounded` 18 `success`；错误态用 `ErrorBanner`（既有规格）+ 一句「下一步做什么」；底部版权说明复用技巧详情页的 11/500 `inkMuted` 居中写法 |

二期页面仍遵循「一屏一个主色实心 CTA」「彩色辅助色只做状态点/小面积标签」「间距只用 4/8 倍数」，不引入新色值、新字号、新圆角或新阴影层级；序列编号（`第 07 / 62 句`）是真实句子顺序，不作装饰性编号。

#### 三期新增组件规格（M9 复练 / M10 反馈与场景）

| 组件 | 规格 |
|---|---|
| 首页「今天练这个」卡 | 复用 `AppCard`（24 圆角 / 16 内边距）；左 `Icons.today_rounded` 18 `primary` + `AppText.cardTitle` 标题；下方 `AppText.section` 推荐标题 + `AppText.caption` 人话理由；底部通栏 `PrimaryButton`「开始」。首页已有主色 CTA 时该卡不再放第二个实心 CTA，只用文字入口 |
| 「今日一条」90 秒练习卡 | `AppCard` 内：`Icons.auto_awesome_rounded` 18 `primary` + 标题 + 右侧 `AppText.caption`「待复练」；参考句放 14 圆角 `primaryWash` 底块、`AppText.body`；中文释义与判分规则用 `AppText.caption`；两枚等宽 `SecondaryButton`（按麦 / 键盘）+ 通栏 `PrimaryButton`（提交）并排按 4/8 网格；结果条用 `success` 12% 或 `warning` 14% 底、12 圆角，不出现分数、星级或进度环 |
| 复练中心反馈条 | 页面顶部通栏 12 圆角提示块，颜色同上；仅 `AppText.body` 一句话，无图标叠加、无动效；练习卡被刷新卸载后仍保留 |
| 复盘补充信息块 | 改法卡内 10 圆角 `primaryWash` 块、10 内边距；「为什么会这么说」用 `AppText.caption`，日常 / 正式两版用 `AppText.bodySecondary`，适用场合用 `AppText.caption`；行距 4；不新增色值、不给两套说法加对比色标签 |
| 场景目标清单 | `SectionTitle`「本场 3 件小事」下 3 行；左侧 20 × 20 圆角 6 `primaryWash` 序号块（`AppText.caption` 11 `primaryDeep`），右侧 `AppText.bodySecondary`；行间距 8；序号是真实目标顺序，不是装饰 |
| 本场目标自评卡 | `AppCard`；左 `Icons.flag_outlined` 18 `primary` + 标题，右 `AppText.caption`「已达成 N/3」；每行 18 图标（达成 `success` 实心 / 未达成 `inkMuted` 空心）+ 目标文字；底部只有待练时才出现一枚 `SecondaryButton`；不使用勾选框组件、不显示百分比 |
| 一句话生成场景卡 | 编辑器顶部 `AppCard`，结构同练习卡（标题 + 说明 + `AppTextField` + 通栏 `SecondaryButton`）；生成中只改按钮文案，不加遮罩或第二个 CTA；失败提示用既有 `showAppToast`，表单保持可手填 |
| 课前 60 秒热身页 | `PageScaffold` + `ListView`；顶部 3 段 26 × 4 圆角 2 进度条（完成 `primary` / 未完成 `line`），间距 6；当前句 `AppCard` 内 `AppText.caption` 序号 + `AppText.body` 英文 + `SecondaryButton`「听一遍」+ `AppTextField` + 通栏 `PrimaryButton`；反馈仅一行 `AppText.caption`，不出现分数、星级或正确率；「跳过」放头部 `actions`，底部再给一枚 `SecondaryButton`，二者都不阻塞开练 |
| 首页 3 分钟轻量入口 | 紧跟「今天练这个」卡之后的一枚通栏 `SecondaryButton`（`Icons.bolt_rounded`），间距 12；上方 `AppText.caption` 一行说明「本周 N 次有效练习 · 轻量 M 次（轻量计入今日分钟，不计入每周 3 次）」；不新增 Tab、不新增第二个主色实心 CTA |
| 3 分钟轻量练习页 | `PageScaffold` + `ListView`；顶部 3 段进度条同热身页；步骤说明用 `AppText.caption`，当前句 `AppText.body`，`AppTextField` + 通栏 `PrimaryButton`；完成态用 28 `success` 图标 + `AppText.cardTitle` + 一句带走的表达 + 通栏 `PrimaryButton`；全程无分数、无星级、无进度环 |
| 进步轨迹卡 | `SectionTitle`「进步轨迹」下每张 `AppCard`（16 内边距）；首行 `AppText.cardTitle` 标题 + 右侧 `AppText.caption`「本周 N%」或「本周样本不足」；中部 88 高 `CustomPaint` 折线（2px `primary` 线 + 3.5 半径实心点 + 1px `line` 基线，样本不足的点断开不补 0）；下方 4 个 `M/D` 周标签 `AppText.caption`；底部 `ExpansionTile`「怎么算的」展开 `AppText.caption` 口径说明；连不出两个周点时整区给 `EmptyState`（文案说明「每周至少 2 次、积累两周后」），不显示单点假趋势；不画目标线、不给等级、不放排名或勋章 |
| 一键加压行 | 对话页输入区模式 Chip 行（语音输入 / 提示 / 我想说）之下一行 `Row`：两枚复用 `_ModeChip`（`Icons.alt_route_rounded`「换个角度追问」、`Icons.trending_up_rounded`「提高难度」），后接 `Expanded` 单行 `AppText.caption`（10 号、`inkMuted`）说明「只影响下一回合，不会自动发送」；选中后文案改为「下一回合：X（可取消）」并出现 `TextButton`「取消」（10 号 `primaryDeep`）；开关关闭时整行不渲染；不加新色值、不做选中态色块 |
| 学习者档案设置开关 | 「设置 → 练习」分组内新增一行 `SettingRow`（`Icons.psychology_alt_outlined`），标题「学习者档案」，`subtitle` 说明用途与「关闭后回到原始对话」，`trailing` 用原生 `Switch`（`activeTrackColor = primary`）；沿用既有 `Divider` 与 4/8 网格间距 |

三期组件仍只用既有色值 Token、字号 Token 与 4/8 网格间距；「已达成 N/3」「第 1 / 3 句」是真实进度，不作装饰；任何反馈位都不使用分数、等级、星级、排行榜或勋章图形。

#### M14 学习路径新增组件规格（先改规范再落代码）

| 组件 | 规格 |
|---|---|
| 首页「下一步」卡 | 由「今天练这个」升级：仍复用 `AppCard`（24 圆角 / 16 内边距 / `AppShadows.card`）；首行 `Icons.today_rounded` 18 `primary` + `AppText.cardTitle`「下一步」+ 右侧 `AppTag`（`primaryWash` 底 + `primaryDeep` 字）显示阶段名；下方 `AppText.section` 推荐标题 + `AppText.caption` 一句可核对的理由；底部通栏 `PrimaryButton`「开始」；其下一行 3 个 `TextButton`（11/500 `primaryDeep`）：「换一个」「今天先跳过」「查看学习路径」。不新增第二个主色实心 CTA，不出现分数 / 百分比 / 等级 / 星级 / 锁图标 |
| 路径页「三问」卡 | `AppCard`；三行 `AppText.caption`(11/500 `inkMuted`) 标签 + `AppText.body` 值，行距 8：「我在哪」「走到哪了」「接下来做什么」；「走到哪了」下方 3 px 线性进度（轨道 `line`、进度 `primary`），旁边只写「已完成 N / M 条」，不写百分比、不画目标线 |
| 阶段梯度条 | 复用 §3.4「进度 → 分步」规格：4 个 10 圆点 + 2 px 连线，已完成 `primary`、当前 `primaryTint` 描边、未到 `line`；下方 11/500 阶段名；4 段都可点（可跳、可退），**不出现锁形图标、不置灰不可点、不显示「未解锁」** |
| 阶段安排清单行 | `AppCard` 内一行，卡间距 8；左 20 × 20 圆角 6 `primaryWash` 序号块（`AppText.caption` 11 `primaryDeep`），中间 `AppText.bodySecondary` 标题 + `AppText.caption` 一句理由，右 `AppTag`（未开始 / 已完成 / 待巩固 / 今天跳过：只用 `primaryDeep` / `success` / `warning` / `inkMuted`）；整行可点直达对应练习；一个阶段 5–7 行，序号是真实推荐顺序 |
| 阶段回顾卡 | `AppCard`；标题 `AppText.cardTitle` + `AppText.caption`「可以往前走了 / 再稳一轮」；三条证据各占一行，`success` 12% 底 10 圆角块、`AppText.caption`；下方 3 枚 `SecondaryButton`（进入下一阶段 / 再巩固一轮 / 换目标重排）竖排间距 8；本页已有「下一步」主 CTA，回顾卡不再放主色实心按钮 |
| 复盘「下一次练这个」卡 | `AppCard`，紧跟 3 条目标自评卡之后；首行 `Icons.arrow_forward_rounded` 18 `primary` + `AppText.cardTitle`；下方 `AppText.section` 下一次内容 + `AppText.caption` 理由；**只放一枚 `SecondaryButton`**，因为复盘页底部操作栏已有主按钮 |
| 场景库阶段标记 | 场景列表卡第三行元信息末尾追加 `AppTag('适合当前阶段', color: primaryDeep, background: primaryWash)`；不新增色值、不隐藏其它场景、不与「自建 / 练过 N 次」冲突；只是提示，不是筛选条件 |
| 设置「学习路径」行 | 「练习」分组内 1 行 `SettingRow`（`Icons.map_outlined`）跳路径页；同分组补 2 行 `SettingRow` 展示既有但原先无入口的「开口复述通过阈值」「每日待复练上限」，`subtitle` 用一句人话说明口径；沿用既有 `Divider`、开关与 `_pick` Sheet，不新增组件 |
| 起点 3 问页 | `PageScaffold` + `ListView`；4 组 `SectionTitle` + `SegmentedControl` / `AppTextField`（目标场合、具体诉求、水平、每次时长 / 每周次数）；底部固定通栏 `PrimaryButton`「生成我的路径」；未配置时路径页用 `EmptyState`（88 圆形 `primaryWash` + 38 图标）引导进入本页 |

M14 只用既有色值 Token、`AppText` 字号与 4/8 网格间距；「已完成 N / M」「第 1 / 4 阶段」是真实进度，不作装饰；任何位置都不出现分数、CEFR 等级、能力雷达、热力图、勋章、连胜或推送。路径是导航层，不改变首页 4 Tab 与「一屏一个主色实心 CTA」约束。

#### 页面头部

- 左右 24，高 56–64；左返回 40 圆形；中标题 11–12/600 `inkSecondary`；右侧占位 40。
- 首页头部为「48 圆角方头像 + 两行文字」，标题 22–24/700，副标题 13/400。

### 3.5 版面常量

```dart
class AppLayout {
  static const designWidth = 393.0;
  static const pagePadding = 24.0;
  static const contentWidth = designWidth - pagePadding * 2; // 345
  static const headerHeight = 56.0;
  static const navHeight = 58.0;
  static const buttonHeight = 50.0;
  static const inputHeight = 48.0;
  static const listItemHeight = 60.0;
  static const cardGap = 12.0;
  static const sectionGap = 28.0;
}
```

### 3.6 使用约束（Do / Don't）

**Do**

- 先做「渐变背景 + 白色大面板」的层次，再放内容。
- 一屏一个主色实心按钮；重要信息用白色卡承载。
- 大圆角 + 低透明蓝紫阴影 + 充足留白。
- 彩色卡只承载「标题 + 一句说明 + 一个元信息 + 3D 插画」。
- 图标统一线性 2 px；插画统一 3D 黏土质感。

**Don't**

- 不要用纯白铺满整屏，也不要用纯黑阴影。
- 不要给主卡加 1 px 灰边框；不要卡片套卡片套卡片。
- 不要在一个屏幕里同时使用主色、粉色、黄色、薄荷四种高饱和色。
- 不要用下划线输入框、方正小圆角按钮、密集表格。
- 不要把 3D 插画替换成扁平图标堆叠；不要把彩色辅助色用于正文。

---

## 四、提取依据与不确定项

### 4.1 实测（可信度高）

- 主色：按钮与课程卡大面积 `#6E8BFF`（110,139,255）。
- 浅紫题面/输入底：`#DFE5FF`（223,229,255）。
- 页面背景：顶部约 `#C5D4FF`，底部约 `#AFBAF1`，整体为蓝紫渐变。
- 白色卡面与白色悬浮导航；导航为胶囊形。
- 主文字为深藏青（约 `#1D2340`），次文字为蓝灰（约 `#7F88A4`）。
- 主按钮为通栏胶囊、主色实心、白字。
- 进度为「圆点 + 连线」分步式，不是百分比条。
- 卡片大圆角、无明显描边；标签为小圆角、浅色描边。
- 课程卡使用 3D 黏土小物件叠放，允许被卡片裁切。

### 4.2 估算（按比例换算，建议落地时微调）

- 393 基准下左右 24、卡片内 18–20、分区间 24–28。
- 卡片圆角 18–24；大面板 28–32；标签 8–10。
- 标题 22–28 / 700；正文 13–14 / 400–500；说明 11–13。
- 主按钮高 50–52；输入高 44–48；底部导航高 56–60。
- 阴影的具体 blur / offset 与透明度。

### 4.3 拿不准（图中未出现或信息不足）

- 原设计使用的具体字体家族（只能判断为几何圆润无衬线）。
- 精确的渐变停止点与角度。
- 分段控件、开关、错误态、加载态的具体样式（文档中为按同一视觉语言推断）。
- 白色内容面板是否为可拖拽 Bottom Sheet，或只是固定圆角容器（仅从拖拽条推断，不能确定）。
- 辅助色的精准色值（粉色卡与黄色插画经过图片压缩，取值有偏差）。
- 原图设计分辨率与是否为 2× 导出，因此字号只能按 393 基准近似。

---

**落地优先级**：先统一颜色（主色、背景渐变、白卡层次）→ 再统一圆角与阴影 → 再统一字号层级 → 最后校准间距与组件细节。前三项决定 80% 的相似度。
