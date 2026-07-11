const API_BASE_URL = 'https://web-production-77031.up.railway.app/api';

const getHeaders = () => {
  const token = localStorage.getItem('auth_token');
  return {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Token ${token}` } : {})
  };
};

// Multipart istekler için: Content-Type header'ı KOYULMAZ, tarayıcı FormData'nın
// boundary'sini kendisi ekler.
const getFileHeaders = () => {
  const token = localStorage.getItem('auth_token');
  return token ? { 'Authorization': `Token ${token}` } : {};
};

export const api = {
  get: async (endpoint) => {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'GET',
      headers: getHeaders(),
    });
    if (!response.ok) {
      if (response.status === 401) {
        localStorage.removeItem('auth_token');
        window.location.href = '/login';
      }
      throw new Error('API Request Failed');
    }
    return response.json();
  },
  post: async (endpoint, data) => {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify(data),
    });
    const responseData = await response.json();
    if (!response.ok) throw responseData;
    return responseData;
  },
  put: async (endpoint, data) => {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'PUT',
      headers: getHeaders(),
      body: JSON.stringify(data),
    });
    const responseData = await response.json();
    if (!response.ok) throw responseData;
    return responseData;
  },
  patch: async (endpoint, data) => {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'PATCH',
      headers: getHeaders(),
      body: JSON.stringify(data),
    });
    const responseData = await response.json();
    if (!response.ok) throw responseData;
    return responseData;
  },
  delete: async (endpoint) => {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'DELETE',
      headers: getHeaders(),
    });
    if (!response.ok) {
      if (response.status === 401) {
        localStorage.removeItem('auth_token');
        window.location.href = '/login';
      }
      throw new Error('API Request Failed');
    }
    // 204 No Content döner; gövde yok.
    return response.status === 204 ? null : response.json().catch(() => null);
  },
  postFile: async (endpoint, formData) => {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: getFileHeaders(),
      body: formData,
    });
    const responseData = await response.json().catch(() => null);
    if (!response.ok) throw responseData || new Error('Yükleme başarısız oldu');
    return responseData;
  },
  putFile: async (endpoint, formData) => {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'PUT',
      headers: getFileHeaders(),
      body: formData,
    });
    const responseData = await response.json().catch(() => null);
    if (!response.ok) throw responseData || new Error('Güncelleme başarısız oldu');
    return responseData;
  },
};
