import 'package:flutter/material.dart';

/// Local asset shown when a product has no usable remote image.
///
/// This path is a Flutter asset, not a network URL. It must only ever be handed
/// to [Image.asset] — never stored in a database field that is meant to hold a
/// product image URL, and never passed to [Image.network].
const String kDefaultProductImageAsset = 'assets/img/default.jpg';

/// Returns [value] as a usable remote image URL, or `null` when it is missing,
/// empty, or not an `http`/`https` URL.
///
/// Persistence code should route product image values through this so a local
/// asset path such as [kDefaultProductImageAsset] can never be written into a
/// column or JSON field that downstream code will treat as a network URL.
String? resolveProductImageUrl(Object? value) {
  if (value is! String) return null;

  final String trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final Uri? uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;

  return trimmed;
}

/// Whether [value] should be rendered with [Image.network].
///
/// `false` means the caller should render [kDefaultProductImageAsset] directly
/// rather than relying on a failed network load to trigger an error builder.
bool isRemoteImageUrl(Object? value) => resolveProductImageUrl(value) != null;

/// Picks the first usable remote image URL from a product's image list.
///
/// Returns `null` when [images] is null, empty, or holds no usable URL.
String? firstProductImageUrl(Object? images) {
  if (images is! List) return null;
  for (final Object? candidate in images) {
    final String? url = resolveProductImageUrl(candidate);
    if (url != null) return url;
  }
  return null;
}

/// Filters [images] down to the usable remote URLs it contains.
///
/// Returns an empty list rather than injecting a local asset path, so callers
/// that later persist this list never write an asset path to the database.
List<String> remoteImageUrls(Object? images) {
  if (images is! List) return <String>[];
  return <String>[
    for (final Object? candidate in images)
      if (resolveProductImageUrl(candidate) case final String url) url,
  ];
}

/// Renders a product image.
///
/// A usable remote URL is loaded with [Image.network] and falls back to
/// [kDefaultProductImageAsset] if the load fails. A missing, empty, or
/// non-remote value renders the local asset directly, without attempting a
/// pointless network request.
Widget productImage(
  Object? value, {
  double? width,
  double? height,
  BoxFit? fit,
}) {
  final String? url = resolveProductImageUrl(value);

  if (url == null) {
    return Image.asset(
      kDefaultProductImageAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }

  return Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => Image.asset(
      kDefaultProductImageAsset,
      width: width,
      height: height,
      fit: fit,
    ),
  );
}
