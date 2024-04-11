import 'package:chat_uikit_demo/demo_localizations.dart';
import 'package:em_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class DownloadFileWidget extends StatefulWidget {
  const DownloadFileWidget({required this.message, super.key});
  final Message message;
  @override
  State<DownloadFileWidget> createState() => _DownloadFileWidgetState();
}

class _DownloadFileWidgetState extends State<DownloadFileWidget> {
  final ChatUIKitDownloadController controller = ChatUIKitDownloadController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.message.displayName ?? DemoLocalizations.downloadFile.localString(context)),
      ),
      body: ChatUIKitDownloadsHelperWidget(
        controller: controller,
        message: widget.message,
        builder: (context, path, name, state, progress) {
          debugPrint('path: $path, name: $name, state: $state, progress: $progress');
          if (state == ChatUIKitMessageDownloadState.success) {
            return Center(
              child: TextButton(
                onPressed: () {
                  OpenFile.open(path);
                },
                child: Text(DemoLocalizations.openFile.localString(context)),
              ),
            );
          } else if (state == ChatUIKitMessageDownloadState.error) {
            return Center(
              child: TextButton(
                onPressed: () {
                  controller.download();
                },
                child: Text(DemoLocalizations.downloadFailed.localString(context)),
              ),
            );
          }
          return Center(
            child: CircularProgressIndicator(
              value: progress.toDouble(),
            ),
          );
        },
      ),
    );
  }
}
