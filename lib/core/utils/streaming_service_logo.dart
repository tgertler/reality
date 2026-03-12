String getStreamingServiceLogo(String service) {
  switch (service.toLowerCase()) {
    case 'netflix':
      return 'logos/netflix.svg';
    case 'rtl+':
      return 'logos/rtl+.svg';
    case 'prime':
<<<<<<< HEAD
      return 'logos/primee.svg';
    case 'joyn':
      return 'logos/joyn.svg';
    case 'paramountplus':
      return 'logos/paramountplus.svg';
=======
      return 'logos/prime.svg';
    case 'joyn':
      return 'logos/joyn.svg';
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
    // Weitere Streaming-Dienste hier hinzufügen
    default:
      return 'logos/default.svg'; // Standard-Logo
  }
}
