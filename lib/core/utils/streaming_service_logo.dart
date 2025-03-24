String getStreamingServiceLogo(String service) {
  switch (service.toLowerCase()) {
    case 'netflix':
      return 'logos/netflix.svg';
    case 'rtl+':
      return 'logos/rtl+.svg';
    case 'prime':
      return 'logos/prime.svg';
    case 'joyn':
      return 'logos/joyn.svg';
    // Weitere Streaming-Dienste hier hinzufügen
    default:
      return 'logos/default.svg'; // Standard-Logo
  }
}
