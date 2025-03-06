// Use dynamic import for node-fetch (ES module)
import('node-fetch').then(fetchModule => {
  const fetch = fetchModule.default;
  
  // Discogs API token from the app
  const token = 'uHdTAYXRutwEauUglilK:NxEMySZdVbSICratWgfNbLpZaEayoZMU';
  
  // Test search endpoint
  async function testSearch() {
  try {
    console.log('Testing Discogs API search...');
    
    // Split token into key and secret
    const [key, secret] = token.split(':');
    
    // Add key and secret as query parameters
    const url = `https://api.discogs.com/database/search?q=nevermind&type=release&format=Vinyl&per_page=3&key=${key}&secret=${secret}`;
    
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'VinylVaultTest/1.0'
      }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    
    const data = await response.json();
    console.log('Search successful!');
    console.log(`Found ${data.results.length} results`);
    console.log('First result:', data.results[0].title);
    
    return data;
  } catch (error) {
    console.error('Search failed:', error.message);
    if (error.message.includes('401')) {
      console.error('Authentication error - token may be invalid or expired');
    }
    throw error;
  }
}

// Test release details endpoint
async function testReleaseDetails(releaseId) {
  try {
    console.log(`Testing Discogs API release details for ID: ${releaseId}...`);
    
    // Split token into key and secret
    const [key, secret] = token.split(':');
    
    // Add key and secret as query parameters
    const url = `https://api.discogs.com/releases/${releaseId}?key=${key}&secret=${secret}`;
    
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'VinylVaultTest/1.0'
      }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    
    const data = await response.json();
    console.log('Release details successful!');
    console.log('Title:', data.title);
    console.log('Artist:', data.artists?.[0]?.name || 'Unknown');
    console.log('Year:', data.year);
    
    return data;
  } catch (error) {
    console.error('Release details failed:', error.message);
    if (error.message.includes('401')) {
      console.error('Authentication error - token may be invalid or expired');
    }
    throw error;
  }
}

// Run the tests
async function runTests() {
  try {
    // Test search
    const searchData = await testSearch();
    
    // If search successful, test release details with the first result
    if (searchData && searchData.results && searchData.results.length > 0) {
      const releaseId = searchData.results[0].id;
      await testReleaseDetails(releaseId);
    }
    
    console.log('\nAll tests completed successfully!');
  } catch (error) {
    console.error('\nTests failed:', error.message);
  }
}

runTests();
});
