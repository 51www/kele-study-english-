import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/app/widgets/common.dart';

/// 布局优化的回归测试：只关心排版，不触碰任何业务状态。
void main() {
  testWidgets('主按钮长文案在窄列中单行显示且不溢出', (tester) async {
    const label = '继续上次（12 轮）· 接着练';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              height: 50,
              child: PrimaryButton(label: label, icon: Icons.play_arrow_rounded),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull, reason: '窄列按钮不应出现溢出异常');
    expect(tester.widget<Text>(find.text(label)).maxLines, 1);
  });

  testWidgets('次按钮长文案在窄列中单行显示且不溢出', (tester) async {
    const label = '还有 3 条待练 · 再练一次';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              height: 50,
              child: SecondaryButton(label: label, icon: Icons.refresh_rounded),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull, reason: '窄列按钮不应出现溢出异常');
    expect(tester.widget<Text>(find.text(label)).maxLines, 1);
  });

  testWidgets('AppButtonRow 宽屏等宽并排、窄屏上下堆叠', (tester) async {
    Widget row(double width) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: AppButtonRow(
                  children: const [
                    SecondaryButton(label: '按麦说一遍', icon: Icons.mic_rounded),
                    SecondaryButton(label: '改用键盘', icon: Icons.keyboard_rounded),
                  ],
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(row(340));
    expect(tester.takeException(), isNull);
    final buttons = find.byType(SecondaryButton);
    expect(buttons, findsNWidgets(2));
    final wideFirst = tester.getCenter(buttons.at(0));
    final wideSecond = tester.getCenter(buttons.at(1));
    expect(wideFirst.dy, closeTo(wideSecond.dy, 1), reason: '宽屏应并排');
    expect(wideFirst.dx, lessThan(wideSecond.dx));

    await tester.pumpWidget(row(240));
    expect(tester.takeException(), isNull);
    final narrowFirst = tester.getCenter(buttons.at(0));
    final narrowSecond = tester.getCenter(buttons.at(1));
    expect(narrowFirst.dx, closeTo(narrowSecond.dx, 1), reason: '窄屏应上下对齐');
    expect(narrowFirst.dy, lessThan(narrowSecond.dy), reason: '窄屏应堆叠');
  });

  testWidgets('AppTag 超长文案不撑破所在行', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: Row(
              children: [
                Icon(Icons.today_rounded, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '下一步',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppTag(label: '第 4 阶段 · 一个非常非常长的阶段名称'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull, reason: '长标签不应撑破所在行');
  });
}
