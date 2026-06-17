import 'package:client/global/colortheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final double elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final Widget? leading;
  final bool showLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
    this.elevation = 4.0,
    this.borderRadius = 24.0,
    this.backgroundColor,
    this.foregroundColor,
    this.centerTitle = true,
    this.leading,
    this.showLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.background;
    final effectiveFg = foregroundColor ?? AppColors.background;

    Widget? leadingWidget;

    if (showLeading) {
      leadingWidget = leading ??
          InkWell(
            onTap: onBackPressed ?? () => Navigator.maybePop(context),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                CupertinoIcons.chevron_back,
                color: effectiveFg,
                size: 26,
              ),
            ),
          );
    } else if (showBackButton && Navigator.canPop(context)) {
      leadingWidget = InkWell(
        onTap: onBackPressed ?? () => Navigator.maybePop(context),
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(
            CupertinoIcons.chevron_back,
            color: effectiveFg,
            size: 26,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: elevation * 3,
            offset: Offset(0, elevation / 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(borderRadius),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: leadingWidget,
          title: Text(
            title,
            style: TextStyle(
              color: effectiveFg,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: centerTitle,
          actions: actions,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
