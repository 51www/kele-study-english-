import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kele_speak/app/widgets/common.dart';
import 'package:kele_speak/features/dictation/pages/material_import_page.dart';

void main() {
  testWidgets('链接导入按钮随音视频链接输入实时变为可点', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MaterialImportPage()),
      ),
    );

    await tester.tap(find.text('链接导入'));
    await tester.pumpAndSettle();

    PrimaryButton importButton() => tester.widget<PrimaryButton>(
          find.byWidgetPredicate(
            (Widget w) => w is PrimaryButton && w.label == '从链接导入',
          ),
        );

    expect(importButton().onPressed, isNull, reason: '未填链接时应禁用');

    await tester.enterText(
      find.byType(TextField).first,
      'https://www.bilibili.com/video/BV1xx411c7mD',
    );
    await tester.pump();
    expect(importButton().onPressed, isNotNull, reason: '填入链接后应可点');

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    expect(importButton().onPressed, isNull, reason: '清空后应重新禁用');
  });
}
