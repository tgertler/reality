String getStreamingServiceLogo(String service) {
  switch (service.toLowerCase()) {
    case 'netflix':
      return 'assets/logos/netflix.svg';
    case 'rtl+':
      return 'assets/logos/rtl+.svg';
    case 'amazon prime video':
      return 'assets/logos/prime.svg';
    case 'joyn':
      return 'assets/logos/joyn.svg';
    case 'paramount+':
      return 'assets/logos/paramountplus.svg';
    // Weitere Streaming-Dienste hier hinzufügen
    default:
      return 'assets/logos/default.svg'; // Standard-Logo
  }
}