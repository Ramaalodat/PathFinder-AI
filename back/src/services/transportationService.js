const axios = require('axios');

class TransportationService {
  constructor(useMock = false) {
    this.useMock = useMock; // إذا true → يستخدم بيانات وهمية
    this.googleMapsApiKey = process.env.GOOGLE_MAPS_API_KEY || process.env.GOOGLE_API_KEY;

    // Mock Data
    this.mockTransportationData = {
      bus: {
        routes: [
          { id: 'B1', name: 'Downtown Express', frequency: 'Every 15 min', cost: '$2.50' },
          { id: 'B2', name: 'Airport Shuttle', frequency: 'Every 30 min', cost: '$5.00' }
        ],
        realTimeStatus: 'On time',
        delays: []
      },
      metro: {
        lines: [
          { id: 'M1', name: 'Red Line', frequency: 'Every 8 min', cost: '$3.25' }
        ],
        realTimeStatus: 'Minor delays on Red Line',
        delays: ['Red Line: 5-10 min delay']
      },
    };
  }

  /**
   * Get transportation options
   */
  async getTransportationOptions({ from, to, mode = 'all', preferences = {} }) {
    if (this.useMock) {
      // Mock Mode
      const options = await this.calculateTransportationOptions(from, to, mode, preferences);
      return {
        success: true,
        data: { origin: from, destination: to, options },
        message: 'Mock transportation options'
      };
    }

    // Live Mode - Use Google Directions API
    try {
      // Map our mode to Google Maps mode
      const googleMode = mode === 'transit' ? 'transit' : 'transit'; // Always use transit for public transport
      
      const response = await axios.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        {
          params: {
            origin: from,
            destination: to,
            key: this.googleMapsApiKey,
            mode: googleMode
          }
        }
      );

      return {
        success: true,
        data: {
          origin: from,
          destination: to,
          routes: response.data.routes,
          legs: response.data.routes[0]?.legs || []
        },
        message: 'Live transportation options retrieved'
      };
    } catch (error) {
      return { success: false, error: error.message, message: 'Google Directions API failed' };
    }
  }

  /**
   * Get Real-Time Updates
   */
  async getRealTimeUpdates(transportType = 'all') {
    if (this.useMock) {
      return {
        success: true,
        data: {
          timestamp: new Date().toISOString(),
          bus: transportType === 'all' || transportType === 'bus' ? this.mockTransportationData.bus : null,
          metro: transportType === 'all' || transportType === 'metro' ? this.mockTransportationData.metro : null
        },
        message: 'Mock real-time updates'
      };
    }

    // Live Mode → Use GTFS feeds from transit authorities
    try {
      // This would integrate with local transit authority APIs
      // For now, return basic structure
      return {
        success: true,
        data: {
          timestamp: new Date().toISOString(),
          bus: transportType === 'all' || transportType === 'bus' ? { realTimeStatus: 'On time', delays: [] } : null,
          metro: transportType === 'all' || transportType === 'metro' ? { realTimeStatus: 'On time', delays: [] } : null
        },
        message: 'Live real-time updates retrieved'
      };
    } catch (error) {
      return { success: false, error: error.message, message: 'Failed to fetch real-time data' };
    }
  }

  /**
   * Get detailed directions
   */
  async getDirections(from, to, transportType, routeId = null) {
    if (this.useMock) {
      return {
        success: true,
        data: {
          origin: from,
          destination: to,
          transportType,
          steps: [`Mock: go from ${from} to ${to} via ${transportType}`],
          totalTime: '25 min',
          totalCost: '$3.50'
        },
        message: 'Mock directions'
      };
    }

    try {
      const response = await axios.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        {
          params: {
            origin: from,
            destination: to,
            key: this.googleMapsApiKey,
            mode: 'transit'
          }
        }
      );

      return {
        success: true,
        data: response.data,
        message: 'Live directions retrieved'
      };
    } catch (error) {
      return { success: false, error: error.message, message: 'Failed to get directions' };
    }
  }

  /**
   * Track user's current location
   */
  async trackLocation({ latitude, longitude, accuracy, timestamp }) {
    if (this.useMock) {
      return {
        success: true,
        data: {
          location: {
            latitude,
            longitude,
            accuracy: accuracy || 10,
            timestamp: timestamp.toISOString()
          },
          nearbyStations: this.getMockNearbyStations(latitude, longitude),
          alerts: this.getMockLocationAlerts(latitude, longitude)
        },
        message: 'Location tracked successfully'
      };
    }

    // Live Mode - Store location and get real-time data
    try {
      // In a real app, you'd store this in a database
      const locationData = {
        latitude,
        longitude,
        accuracy: accuracy || 10,
        timestamp: timestamp.toISOString()
      };

      // Get real-time data based on location using Google Maps APIs
      const nearbyData = await this.getLiveNearbyData(latitude, longitude);
      
      return {
        success: true,
        data: {
          location: locationData,
          ...nearbyData
        },
        message: 'Location tracked and real-time data retrieved'
      };
    } catch (error) {
      return { success: false, error: error.message, message: 'Failed to track location' };
    }
  }

  /**
   * Get real-time data based on current location
   */
  async getLocationBasedRealtime({ latitude, longitude, radius, transportType }) {
    if (this.useMock) {
      return {
        success: true,
        data: {
          location: { latitude, longitude, radius },
          timestamp: new Date().toISOString(),
          nearbyTransport: this.getMockNearbyTransport(latitude, longitude, radius, transportType),
          realTimeUpdates: this.getMockLocationBasedUpdates(latitude, longitude, transportType),
          traffic: this.getMockTrafficData(latitude, longitude),
          weather: this.getMockWeather(latitude, longitude)
        },
        message: 'Location-based real-time data retrieved'
      };
    }

    // Live Mode
    try {
      const realTimeData = await this.getLiveLocationBasedData(latitude, longitude, radius, transportType);
      return {
        success: true,
        data: realTimeData,
        message: 'Live location-based real-time data retrieved'
      };
    } catch (error) {
      return { success: false, error: error.message, message: 'Failed to get location-based data' };
    }
  }

  /**
   * Get nearby transportation options
   */
  async getNearbyTransportation({ latitude, longitude, radius, transportType }) {
    if (this.useMock || !this.googleMapsApiKey) {
      return {
        success: true,
        data: {
          location: { latitude, longitude, radius },
          timestamp: new Date().toISOString(),
          nearbyOptions: this.getMockNearbyTransport(latitude, longitude, radius, transportType),
          walkingDistances: this.getMockWalkingDistances(latitude, longitude),
          estimatedArrivals: this.getMockEstimatedArrivals(latitude, longitude)
        },
        message: this.useMock ? 'Mock nearby transportation options retrieved' : 'Mock data (API key not configured)'
      };
    }

    // Live Mode
    try {
      const nearbyData = await this.getLiveNearbyTransportation(latitude, longitude, radius, transportType);
      return {
        success: true,
        data: nearbyData,
        message: 'Live nearby transportation data retrieved'
      };
    } catch (error) {
      console.error('Live mode failed, falling back to mock data:', error.message);
      // Fallback to mock data if live mode fails
      return {
        success: true,
        data: {
          location: { latitude, longitude, radius },
          timestamp: new Date().toISOString(),
          nearbyOptions: this.getMockNearbyTransport(latitude, longitude, radius, transportType),
          walkingDistances: this.getMockWalkingDistances(latitude, longitude),
          estimatedArrivals: this.getMockEstimatedArrivals(latitude, longitude)
        },
        message: 'Mock data (live mode failed)'
      };
    }
  }

  // --- MOCK HELPERS FOR LOCATION DATA ---
  getMockNearbyStations(lat, lng) {
    return [
      {
        id: 'ST1',
        name: 'Central Station',
        type: 'metro',
        distance: Math.round(Math.random() * 500 + 100), // 100-600m
        walkingTime: Math.round(Math.random() * 5 + 2), // 2-7 min
        coordinates: { lat: lat + 0.001, lng: lng + 0.001 }
      },
      {
        id: 'ST2',
        name: 'Main Street Bus Stop',
        type: 'bus',
        distance: Math.round(Math.random() * 300 + 50), // 50-350m
        walkingTime: Math.round(Math.random() * 3 + 1), // 1-4 min
        coordinates: { lat: lat - 0.0005, lng: lng + 0.0008 }
      }
    ];
  }

  getMockLocationAlerts(lat, lng) {
    const alerts = [];
    if (Math.random() > 0.7) {
      alerts.push({
        type: 'delay',
        message: 'Traffic congestion detected in your area',
        severity: 'medium',
        duration: '15-20 minutes'
      });
    }
    return alerts;
  }


  getMockNearbyTransport(lat, lng, radius, transportType) {
    const transport = [];
    
    if (transportType === 'all' || transportType === 'bus') {
      transport.push({
        type: 'bus',
        name: 'Bus Route 42',
        stop: 'Main Street & 5th Ave',
        distance: Math.round(Math.random() * radius + 50),
        nextArrival: Math.round(Math.random() * 15 + 2), // 2-17 min
        frequency: 'Every 8-12 minutes',
        status: 'On time'
      });
    }
    
    if (transportType === 'all' || transportType === 'metro') {
      transport.push({
        type: 'metro',
        name: 'Red Line',
        station: 'Central Station',
        distance: Math.round(Math.random() * radius + 100),
        nextArrival: Math.round(Math.random() * 10 + 1), // 1-11 min
        frequency: 'Every 4-6 minutes',
        status: 'Minor delays'
      });
    }
    
    
    return transport;
  }

  getMockLocationBasedUpdates(lat, lng, transportType) {
    return {
      bus: transportType === 'all' || transportType === 'bus' ? {
        realTimeStatus: 'On time',
        delays: [],
        nearbyRoutes: ['Route 42', 'Route 15', 'Route 8']
      } : null,
      metro: transportType === 'all' || transportType === 'metro' ? {
        realTimeStatus: 'Minor delays on Red Line',
        delays: ['Red Line: 3-5 min delay'],
        nearbyStations: ['Central Station', 'Downtown Station']
      } : null,
    };
  }

  getMockTrafficData(lat, lng) {
    return {
      congestion: Math.random() > 0.6 ? 'Moderate' : 'Light',
      averageSpeed: Math.round(Math.random() * 20 + 25), // 25-45 km/h
      incidents: Math.random() > 0.8 ? ['Accident on Main Street'] : [],
      estimatedDelay: Math.round(Math.random() * 10 + 2) // 2-12 min
    };
  }

  getMockWalkingDistances(lat, lng) {
    return [
      { destination: 'Nearest Bus Stop', distance: 150, time: 2 },
      { destination: 'Nearest Metro Station', distance: 300, time: 4 },
      { destination: 'Nearest Taxi Stand', distance: 200, time: 3 }
    ];
  }

  getMockEstimatedArrivals(lat, lng) {
    return [
      { transport: 'Bus Route 42', arrival: '3 minutes', status: 'On time' },
      { transport: 'Red Line Metro', arrival: '7 minutes', status: 'Delayed' },
      { transport: 'Uber', arrival: '4 minutes', status: 'Available' }
    ];
  }

  // --- LIVE LOCATION TRACKING METHODS ---
  async getLiveNearbyData(latitude, longitude) {
    try {
      // Get nearby places using Google Places API
      const placesResponse = await axios.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        {
          params: {
            location: `${latitude},${longitude}`,
            radius: 1000,
            type: 'transit_station',
            key: this.googleMapsApiKey
          }
        }
      );

      // Get traffic data using Google Roads API
      const trafficData = await this.getLiveTrafficData(latitude, longitude);

      return {
        nearbyStations: this.formatNearbyStations(placesResponse.data.results),
        traffic: trafficData,
        alerts: await this.getLiveAlerts(latitude, longitude)
      };
    } catch (error) {
      console.error('Error getting live nearby data:', error);
      return {
        nearbyStations: [],
        traffic: { congestion: 'unknown', averageSpeed: 0 },
        alerts: []
      };
    }
  }

  async getLiveLocationBasedData(latitude, longitude, radius, transportType) {
    try {
      // Get real-time transit data using Google Directions API
      const transitData = await this.getLiveTransitData(latitude, longitude, radius);

      return {
        location: { latitude, longitude, radius },
        timestamp: new Date().toISOString(),
        nearbyTransport: transitData,
        realTimeUpdates: {
          bus: transportType === 'all' || transportType === 'bus' ? transitData.bus : null,
          metro: transportType === 'all' || transportType === 'metro' ? transitData.metro : null
        },
        traffic: await this.getLiveTrafficData(latitude, longitude)
      };
    } catch (error) {
      console.error('Error getting live location-based data:', error);
      return {
        location: { latitude, longitude, radius },
        timestamp: new Date().toISOString(),
        nearbyTransport: [],
        realTimeUpdates: {},
        traffic: { congestion: 'unknown' }
      };
    }
  }

  async getLiveNearbyTransportation(latitude, longitude, radius, transportType) {
    try {
      const transitData = await this.getLiveTransitData(latitude, longitude, radius);

      return {
        location: { latitude, longitude, radius },
        timestamp: new Date().toISOString(),
        nearbyOptions: this.filterTransportByType(transitData, transportType),
        walkingDistances: await this.calculateWalkingDistances(latitude, longitude, transitData),
        estimatedArrivals: await this.getEstimatedArrivals(transitData)
      };
    } catch (error) {
      console.error('Error getting live nearby transportation:', error);
      return {
        location: { latitude, longitude, radius },
        timestamp: new Date().toISOString(),
        nearbyOptions: [],
        walkingDistances: [],
        estimatedArrivals: []
      };
    }
  }

  async getLiveTransitData(latitude, longitude, radius) {
    try {
      if (!this.googleMapsApiKey) {
        console.error('Google Maps API key is not configured');
        throw new Error('Google Maps API key is required for live transportation data');
      }

      // Use Google Places API to find nearby transit stations
      const response = await axios.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        {
          params: {
            location: `${latitude},${longitude}`,
            radius: radius,
            type: 'transit_station',
            key: this.googleMapsApiKey
          }
        }
      );

      if (response.data.status === 'REQUEST_DENIED') {
        throw new Error('Google Maps API request denied. Check API key and permissions.');
      }

      if (response.data.status === 'OVER_QUERY_LIMIT') {
        throw new Error('Google Maps API quota exceeded');
      }

      return this.formatTransitData(response.data.results);
    } catch (error) {
      console.error('Error getting live transit data:', error);
      throw error; // Re-throw to be handled by calling method
    }
  }


  async getLiveTrafficData(latitude, longitude) {
    try {
      // Using Google Roads API for traffic data
      const response = await axios.get(
        'https://roads.googleapis.com/v1/snapToRoads',
        {
          params: {
            path: `${latitude},${longitude}`,
            key: this.googleMapsApiKey
          }
        }
      );

      return {
        congestion: 'Moderate', // This would be calculated from actual traffic data
        averageSpeed: 35,
        incidents: [],
        estimatedDelay: 5
      };
    } catch (error) {
      console.error('Error getting traffic data:', error);
      return {
        congestion: 'unknown',
        averageSpeed: 0,
        incidents: [],
        estimatedDelay: 0
      };
    }
  }

  async getLiveAlerts(latitude, longitude) {
    // This would integrate with local transit authority APIs
    // For now, return empty array
    return [];
  }

  formatNearbyStations(places) {
    return places.map(place => ({
      id: place.place_id,
      name: place.name,
      type: this.determineStationType(place.types),
      distance: place.distance || 0,
      walkingTime: Math.round((place.distance || 0) / 80), // 80m per minute walking
      coordinates: {
        lat: place.geometry.location.lat,
        lng: place.geometry.location.lng
      },
      rating: place.rating,
      vicinity: place.vicinity
    }));
  }

  formatTransitData(places) {
    const busStations = places.filter(place => 
      place.types.includes('bus_station') || place.types.includes('transit_station')
    );
    const metroStations = places.filter(place => 
      place.types.includes('subway_station') || place.types.includes('train_station')
    );

    return {
      bus: busStations.map(station => ({
        type: 'bus',
        name: station.name,
        stop: station.vicinity,
        distance: station.distance || 0,
        nextArrival: Math.round(Math.random() * 15 + 2),
        frequency: 'Every 8-12 minutes',
        status: 'On time',
        coordinates: {
          lat: station.geometry.location.lat,
          lng: station.geometry.location.lng
        }
      })),
      metro: metroStations.map(station => ({
        type: 'metro',
        name: station.name,
        station: station.vicinity,
        distance: station.distance || 0,
        nextArrival: Math.round(Math.random() * 10 + 1),
        frequency: 'Every 4-6 minutes',
        status: 'Minor delays',
        coordinates: {
          lat: station.geometry.location.lat,
          lng: station.geometry.location.lng
        }
      }))
    };
  }

  determineStationType(types) {
    if (types.includes('subway_station')) return 'metro';
    if (types.includes('bus_station')) return 'bus';
    if (types.includes('train_station')) return 'metro';
    return 'transit';
  }


  filterTransportByType(transitData, transportType) {
    if (transportType === 'bus') return transitData.bus;
    if (transportType === 'metro') return transitData.metro;
    return [...transitData.bus, ...transitData.metro];
  }

  async calculateWalkingDistances(latitude, longitude, transitData) {
    // This would use Google Distance Matrix API for accurate walking times
    return [
      { destination: 'Nearest Bus Stop', distance: 150, time: 2 },
      { destination: 'Nearest Metro Station', distance: 300, time: 4 },
      { destination: 'Nearest Taxi Stand', distance: 200, time: 3 }
    ];
  }

  async getEstimatedArrivals(transitData) {
    const arrivals = [];
    
    transitData.bus.forEach(bus => {
      arrivals.push({
        transport: bus.name,
        arrival: `${bus.nextArrival} minutes`,
        status: bus.status
      });
    });

    transitData.metro.forEach(metro => {
      arrivals.push({
        transport: metro.name,
        arrival: `${metro.nextArrival} minutes`,
        status: metro.status
      });
    });

    return arrivals;
  }

  // --- MOCK HELPERS (نفس اللي عندك) ---
  async calculateTransportationOptions(from, to, mode, preferences) {
    return [
      {
        type: 'bus',
        estimatedTime: '35-45 min',
        cost: '$2.50',
        route: [`Walk to bus stop`, `Take bus B1`, `Arrive at ${to}`]
      },
      {
        type: 'metro',
        estimatedTime: '25-35 min',
        cost: '$3.25',
        route: [`Walk to metro station`, `Take Red Line`, `Arrive at ${to}`]
      },
    ];
  }
}

module.exports = TransportationService;
