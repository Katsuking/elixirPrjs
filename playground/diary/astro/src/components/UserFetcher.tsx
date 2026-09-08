import { useState, useEffect } from 'react';

// Type definition for JSONPlaceholder User
interface User {
  id: number;
  name: string;
  email: string;
  company: {
    name: string;
  };
}

// React Component fetching data from JSONPlaceholder
export default function UserFetcher() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Fetch users from JSONPlaceholder API
    fetch('https://jsonplaceholder.typicode.com/users')
      .then((res) => {
        if (!res.ok) {
          throw new Error('Failed to fetch user data');
        }
        return res.json();
      })
      .then((data: User[]) => {
        setUsers(data.slice(0, 5)); // Take first 5 users for clean UI
        setLoading(false);
      })
      .catch((err: Error) => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  return (
    <div style={{
      padding: '1.5rem',
      backgroundColor: '#1e293b',
      borderRadius: '0.75rem',
      border: '1px solid #334155',
      color: '#f8fafc',
      margin: '1.5rem 0'
    }}>
      <h3 style={{ marginTop: 0, color: '#38bdf8' }}>⚛️ React Component: JSONPlaceholder Users</h3>

      {loading && <p style={{ color: '#94a3b8' }}>Loading users from API...</p>}
      {error && <p style={{ color: '#f43f5e' }}>Error: {error}</p>}

      {!loading && !error && (
        <ul style={{ paddingLeft: '1.25rem', margin: 0 }}>
          {users.map((user) => (
            <li key={user.id} style={{ marginBottom: '0.5rem' }}>
              <strong>{user.name}</strong> ({user.email}) - <em style={{ color: '#cbd5e1' }}>{user.company.name}</em>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
