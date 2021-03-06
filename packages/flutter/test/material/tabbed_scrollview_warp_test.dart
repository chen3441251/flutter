// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// This is a regression test for https://github.com/flutter/flutter/issues/10549
// which was failing because _SliverPersistentHeaderElement.visitChildren()
// didn't check child != null before visiting its child.

class MySliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 50.0;

  @override
  double get maxExtent => 150.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => const Placeholder(color: Colors.teal);

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  static const int tabCount = 3;
  TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = new TabController(initialIndex: 0, length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        bottom: new TabBar(
          controller: tabController,
          tabs: new List<Widget>.generate(tabCount, (int index) => new Tab(text: 'Tab $index')).toList(),
        ),
      ),
      body: new TabBarView(
        controller: tabController,
        children: new List<Widget>.generate(tabCount, (int index) {
          return new CustomScrollView(
            // The bug only occurs when this key is included
            key: new ValueKey<String>('Page $index'),
            slivers: <Widget>[
              new SliverPersistentHeader(
                delegate: new MySliverPersistentHeaderDelegate(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

void main() {
  testWidgets('Tabbed CustomScrollViews, warp from tab 1 to 3', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(home: new MyHomePage()));

    // should not crash.
    await tester.tap(find.text('Tab 2'));
    await tester.pumpAndSettle();
  });
}
