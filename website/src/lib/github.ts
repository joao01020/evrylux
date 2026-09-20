export const GITHUB_OWNER = 'joao01020';
export const GITHUB_REPO = 'ghost-core';
export const GITHUB_API_VERSION = '2026-03-10';

export type GitHubContributor = {
  login: string;
  id: number;
  avatar_url: string;
  html_url: string;
  contributions: number;
  type: string;
};

export type GitHubUser = {
  login: string;
  id: number;
  name: string | null;
  avatar_url: string;
  html_url: string;
  bio: string | null;
  location: string | null;
  blog: string | null;
  company: string | null;
  public_repos: number;
  followers: number;
  following: number;
};

export type GitHubCommit = {
  sha: string;
  html_url: string;
  commit: {
    message: string;
    author: {
      name: string;
      email: string;
      date: string;
    } | null;
  };
  author: {
    login: string;
    avatar_url: string;
    html_url: string;
  } | null;
};

export type GitHubIssueSearchItem = {
  html_url: string;
  number: number;
  title: string;
  state: 'open' | 'closed';
  created_at: string;
  updated_at: string;
  closed_at: string | null;
  user: {
    login: string;
    avatar_url: string;
    html_url: string;
  } | null;
  pull_request?: {
    url?: string;
    html_url?: string;
    diff_url?: string;
    patch_url?: string;
    merged_at?: string | null;
  };
};

export type GitHubSearchResponse = {
  total_count: number;
  incomplete_results: boolean;
  items: GitHubIssueSearchItem[];
};

export type ContributorActivity = {
  contributor: GitHubContributor;
  profile: GitHubUser | null;
  commits: GitHubCommit[];
  pullRequests: GitHubIssueSearchItem[];
  issues: GitHubIssueSearchItem[];
  pullRequestCount: number;
  issueCount: number;
};

function getGitHubToken(): string | undefined {
  const token = import.meta.env.GITHUB_TOKEN?.trim();

  if (!token) {
    return undefined;
  }

  return token;
}

export function githubHeaders(): HeadersInit {
  const token = getGitHubToken();

  return {
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': GITHUB_API_VERSION,
    ...(token
      ? {
          Authorization: `Bearer ${token}`,
        }
      : {}),
  };
}

export async function githubFetch<T>(
  url: string,
): Promise<T | null> {
  try {
    const response = await fetch(
      url,
      {
        headers: githubHeaders(),
      },
    );

    if (!response.ok) {
      console.warn(
        `[EVRYLUX] GitHub API ${response.status}: ${url}`,
      );

      return null;
    }

    return (await response.json()) as T;
  } catch (error) {
    console.warn(
      `[EVRYLUX] Falha ao consultar GitHub: ${url}`,
      error,
    );

    return null;
  }
}

export async function getContributors(
  perPage = 100,
): Promise<GitHubContributor[]> {
  const contributors =
    await githubFetch<GitHubContributor[]>(
      `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contributors?per_page=${perPage}`,
    );

  return contributors ?? [];
}

export async function getContributorByLogin(
  login: string,
): Promise<GitHubContributor | null> {
  const contributors =
    await getContributors();

  return (
    contributors.find(
      (contributor) =>
        contributor.login.toLowerCase() ===
        login.toLowerCase(),
    ) ?? null
  );
}

export async function getGitHubUser(
  login: string,
): Promise<GitHubUser | null> {
  return githubFetch<GitHubUser>(
    `https://api.github.com/users/${encodeURIComponent(login)}`,
  );
}

export async function getContributorCommits(
  login: string,
  perPage = 8,
): Promise<GitHubCommit[]> {
  const commits =
    await githubFetch<GitHubCommit[]>(
      `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/commits?author=${encodeURIComponent(login)}&per_page=${perPage}`,
    );

  return commits ?? [];
}

export async function getContributorPullRequests(
  login: string,
  perPage = 5,
): Promise<GitHubSearchResponse> {
  const query =
    `repo:${GITHUB_OWNER}/${GITHUB_REPO} author:${login} is:pr`;

  const result =
    await githubFetch<GitHubSearchResponse>(
      `https://api.github.com/search/issues?q=${encodeURIComponent(query)}&sort=created&order=desc&per_page=${perPage}`,
    );

  return (
    result ?? {
      total_count: 0,
      incomplete_results: false,
      items: [],
    }
  );
}

export async function getContributorIssues(
  login: string,
  perPage = 5,
): Promise<GitHubSearchResponse> {
  const query =
    `repo:${GITHUB_OWNER}/${GITHUB_REPO} author:${login} is:issue`;

  const result =
    await githubFetch<GitHubSearchResponse>(
      `https://api.github.com/search/issues?q=${encodeURIComponent(query)}&sort=created&order=desc&per_page=${perPage}`,
    );

  return (
    result ?? {
      total_count: 0,
      incomplete_results: false,
      items: [],
    }
  );
}

export async function getContributorActivity(
  contributor: GitHubContributor,
): Promise<ContributorActivity> {
  const login = contributor.login;

  const [
    profile,
    commits,
    pullRequests,
    issues,
  ] = await Promise.all([
    getGitHubUser(login),
    getContributorCommits(login),
    getContributorPullRequests(login),
    getContributorIssues(login),
  ]);

  return {
    contributor,
    profile,
    commits,
    pullRequests: pullRequests.items,
    issues: issues.items,
    pullRequestCount: pullRequests.total_count,
    issueCount: issues.total_count,
  };
}

export function formatGitHubDate(
  date: string | null | undefined,
): string {
  if (!date) {
    return 'Data indisponível';
  }

  return new Intl.DateTimeFormat(
    'pt-BR',
    {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    },
  ).format(
    new Date(date),
  );
}

export function firstCommitLine(
  message: string,
): string {
  return (
    message
      .split('\n')[0]
      ?.trim() ||
    'Commit sem descrição'
  );
}

export function normalizeExternalUrl(
  value: string | null | undefined,
): string | null {
  const url = value?.trim();

  if (!url) {
    return null;
  }

  if (
    url.startsWith('http://') ||
    url.startsWith('https://')
  ) {
    return url;
  }

  return `https://${url}`;
}

export function repositoryUrl(): string {
  return `https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}`;
}

export function contributorCommitsUrl(
  login: string,
): string {
  return (
    `${repositoryUrl()}/commits` +
    `?author=${encodeURIComponent(login)}`
  );
}
