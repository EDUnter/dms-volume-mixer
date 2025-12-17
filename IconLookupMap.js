.pragma library

// Some applications do not expose correct node properties values,
// which causes desktop icon lookup to fail. You can inspect the property using:
//       pw-cli i <stream-id>
//
// The node properties used to find an icon on the desktop are, depending on their availability,
// respectively the following:
//      node.properties["pipewire.access.portal.app_id"] || node.properties["application.process.binary"] || node.name
//
// If you encounter such a case, add a mapping below from the reported ID (moddedId)
// to the correct desktop entry ID.
const iconLookupMap = new Map([
  ["firefox", "org.mozilla.firefox"],
  ["steamwebhelper", "steam"],
  ["wine64-preloader", "steam"],
  ["wine-preloader", "steam"],
]);

function get(appIconId) {
  return iconLookupMap.get(appIconId);
}
