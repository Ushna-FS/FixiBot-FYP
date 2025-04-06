import 'package:flutter/material.dart';

class UserJourneyModel {
  PageController? pageViewController;

  int get currentPageIndex {
    if (pageViewController != null &&
        pageViewController!.hasClients &&
        pageViewController!.page != null) {
      return pageViewController!.page!.round();
    }
    return 0;
  }

  void dispose() {
    pageViewController?.dispose();
  }
}


// import 'package:flutter/material.dart';
// class UserJourneyModel {
//   PageController? pageViewController;

//   int get pageViewCurrentIndex => pageViewController != null &&
//           pageViewController!.hasClients &&
//           pageViewController!.page != null
//       ? pageViewController!.page!.round()
//       : 0;

//   @override
//   void initState(BuildContext context) {}

//   @override
//   void dispose() {}
// }
