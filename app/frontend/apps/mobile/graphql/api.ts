import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type Maybe<T> = T | null;
export type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
export type MakeOptional<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]?: Maybe<T[SubKey]> };
export type MakeMaybe<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]: Maybe<T[SubKey]> };
export type ReactiveFunction<TParam> = () => TParam;
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: string;
  String: string;
  Boolean: boolean;
  Int: number;
  Float: number;
  /** An ISO 8601-encoded date */
  ISO8601Date: any;
  /** An ISO 8601-encoded datetime */
  ISO8601DateTime: any;
  /** Represents untyped JSON */
  JSON: any;
};

/** Autogenerated return type of Login */
export type LoginPayload = {
  __typename?: 'LoginPayload';
  /** The logged-in user */
  currentUser: User;
  /** The current session */
  session: Session;
};

/** Autogenerated return type of Logout */
export type LogoutPayload = {
  __typename?: 'LogoutPayload';
  /** Was the logout successful? */
  success: Scalars['Boolean'];
};

/** All available mutations. */
export type Mutations = {
  __typename?: 'Mutations';
  /** Performs a user login to create a session */
  login?: Maybe<LoginPayload>;
  /** End the current session */
  logout?: Maybe<LogoutPayload>;
};


/** All available mutations. */
export type MutationsLoginArgs = {
  fingerprint: Scalars['String'];
  login: Scalars['String'];
  password: Scalars['String'];
};

/** An object with an ID. */
export type Node = {
  /** ID of the object. */
  id: Scalars['ID'];
};

/** Organizations that users can belong to */
export type Organization = Node & {
  __typename?: 'Organization';
  active: Scalars['Boolean'];
  /** Create date/time of the record */
  createdAt: Scalars['ISO8601DateTime'];
  /** User that created this record */
  createdBy: User;
  domain?: Maybe<Scalars['String']>;
  domainAssignment: Scalars['Boolean'];
  id: Scalars['ID'];
  members: UserConnection;
  name: Scalars['String'];
  note?: Maybe<Scalars['String']>;
  shared: Scalars['Boolean'];
  /** Last update date/time of the record */
  updatedAt: Scalars['ISO8601DateTime'];
  /** Last user that updated this record */
  updatedBy: User;
};


/** Organizations that users can belong to */
export type OrganizationMembersArgs = {
  after?: Maybe<Scalars['String']>;
  before?: Maybe<Scalars['String']>;
  first?: Maybe<Scalars['Int']>;
  last?: Maybe<Scalars['Int']>;
};

/** Information about pagination in a connection. */
export type PageInfo = {
  __typename?: 'PageInfo';
  /** When paginating forwards, the cursor to continue. */
  endCursor?: Maybe<Scalars['String']>;
  /** When paginating forwards, are there more items? */
  hasNextPage: Scalars['Boolean'];
  /** When paginating backwards, are there more items? */
  hasPreviousPage: Scalars['Boolean'];
  /** When paginating backwards, the cursor to continue. */
  startCursor?: Maybe<Scalars['String']>;
};

/** All available queries */
export type Queries = {
  __typename?: 'Queries';
  /** Fetches an object given its ID. */
  node?: Maybe<Node>;
  /** Fetches a list of objects given a list of IDs. */
  nodes: Array<Maybe<Node>>;
  /** Information about the current user session */
  session: Session;
};


/** All available queries */
export type QueriesNodeArgs = {
  id: Scalars['ID'];
};


/** All available queries */
export type QueriesNodesArgs = {
  ids: Array<Scalars['ID']>;
};

/** Data of a current session */
export type Session = {
  __typename?: 'Session';
  data?: Maybe<Scalars['JSON']>;
  sessionId: Scalars['String'];
};

/** Users (admins, agents and customers) */
export type User = Node & {
  __typename?: 'User';
  active: Scalars['Boolean'];
  address?: Maybe<Scalars['String']>;
  city?: Maybe<Scalars['String']>;
  country?: Maybe<Scalars['String']>;
  /** Create date/time of the record */
  createdAt: Scalars['ISO8601DateTime'];
  /** User that created this record */
  createdById: Scalars['Int'];
  department?: Maybe<Scalars['String']>;
  email?: Maybe<Scalars['String']>;
  fax?: Maybe<Scalars['String']>;
  firstname?: Maybe<Scalars['String']>;
  id: Scalars['ID'];
  image?: Maybe<Scalars['String']>;
  imageSource?: Maybe<Scalars['String']>;
  lastLogin?: Maybe<Scalars['ISO8601DateTime']>;
  lastname?: Maybe<Scalars['String']>;
  login: Scalars['String'];
  loginFailed: Scalars['Int'];
  mobile?: Maybe<Scalars['String']>;
  note?: Maybe<Scalars['String']>;
  organization?: Maybe<Organization>;
  outOfOffice: Scalars['Boolean'];
  outOfOfficeEndAt?: Maybe<Scalars['ISO8601Date']>;
  outOfOfficeReplacementId?: Maybe<Scalars['Int']>;
  outOfOfficeStartAt?: Maybe<Scalars['ISO8601Date']>;
  password?: Maybe<Scalars['String']>;
  phone?: Maybe<Scalars['String']>;
  preferences?: Maybe<Scalars['JSON']>;
  source?: Maybe<Scalars['String']>;
  street?: Maybe<Scalars['String']>;
  /** Last update date/time of the record */
  updatedAt: Scalars['ISO8601DateTime'];
  /** Last user that updated this record */
  updatedById: Scalars['Int'];
  verified: Scalars['Boolean'];
  vip?: Maybe<Scalars['Boolean']>;
  web?: Maybe<Scalars['String']>;
  zip?: Maybe<Scalars['String']>;
};

/** The connection type for User. */
export type UserConnection = {
  __typename?: 'UserConnection';
  /** A list of edges. */
  edges?: Maybe<Array<Maybe<UserEdge>>>;
  /** A list of nodes. */
  nodes?: Maybe<Array<Maybe<User>>>;
  /** Information to aid in pagination. */
  pageInfo: PageInfo;
};

/** An edge in a connection. */
export type UserEdge = {
  __typename?: 'UserEdge';
  /** A cursor for use in pagination. */
  cursor: Scalars['String'];
  /** The item at the end of the edge. */
  node?: Maybe<User>;
};

export type LoginMutationVariables = Exact<{
  login: Scalars['String'];
  password: Scalars['String'];
  fingerprint: Scalars['String'];
}>;


export type LoginMutation = { __typename?: 'Mutations', login?: { __typename?: 'LoginPayload', currentUser: { __typename?: 'User', firstname?: string | null | undefined, lastname?: string | null | undefined }, session: { __typename?: 'Session', sessionId: string, data?: any | null | undefined } } | null | undefined };

export type LogoutMutationVariables = Exact<{ [key: string]: never; }>;


export type LogoutMutation = { __typename?: 'Mutations', logout?: { __typename?: 'LogoutPayload', success: boolean } | null | undefined };

export type SessionQueryVariables = Exact<{ [key: string]: never; }>;


export type SessionQuery = { __typename?: 'Queries', session: { __typename?: 'Session', sessionId: string, data?: any | null | undefined } };


export const LoginDocument = gql`
    mutation login($login: String!, $password: String!, $fingerprint: String!) {
  login(login: $login, password: $password, fingerprint: $fingerprint) {
    currentUser {
      firstname
      lastname
    }
    session {
      sessionId
      data
    }
  }
}
    `;

/**
 * __useLoginMutation__
 *
 * To run a mutation, you first call `useLoginMutation` within a Vue component and pass it any options that fit your needs.
 * When your component renders, `useLoginMutation` returns an object that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - Several other properties: https://v4.apollo.vuejs.org/api/use-mutation.html#return
 *
 * @param options that will be passed into the mutation, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/mutation.html#options;
 *
 * @example
 * const { mutate, loading, error, onDone } = useLoginMutation({
 *   variables: {
 *     login: // value for 'login'
 *     password: // value for 'password'
 *     fingerprint: // value for 'fingerprint'
 *   },
 * });
 */
export function useLoginMutation(options: VueApolloComposable.UseMutationOptions<LoginMutation, LoginMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<LoginMutation, LoginMutationVariables>>) {
  return VueApolloComposable.useMutation<LoginMutation, LoginMutationVariables>(LoginDocument, options);
}
export type LoginMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<LoginMutation, LoginMutationVariables>;
export const LogoutDocument = gql`
    mutation logout {
  logout {
    success
  }
}
    `;

/**
 * __useLogoutMutation__
 *
 * To run a mutation, you first call `useLogoutMutation` within a Vue component and pass it any options that fit your needs.
 * When your component renders, `useLogoutMutation` returns an object that includes:
 * - A mutate function that you can call at any time to execute the mutation
 * - Several other properties: https://v4.apollo.vuejs.org/api/use-mutation.html#return
 *
 * @param options that will be passed into the mutation, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/mutation.html#options;
 *
 * @example
 * const { mutate, loading, error, onDone } = useLogoutMutation();
 */
export function useLogoutMutation(options: VueApolloComposable.UseMutationOptions<LogoutMutation, LogoutMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<LogoutMutation, LogoutMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<LogoutMutation, LogoutMutationVariables>(LogoutDocument, options);
}
export type LogoutMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<LogoutMutation, LogoutMutationVariables>;
export const SessionDocument = gql`
    query session {
  session {
    sessionId
    data
  }
}
    `;

/**
 * __useSessionQuery__
 *
 * To run a query within a Vue component, call `useSessionQuery` and pass it any options that fit your needs.
 * When your component renders, `useSessionQuery` returns an object from Apollo Client that contains result, loading and error properties
 * you can use to render your UI.
 *
 * @param options that will be passed into the query, supported options are listed on: https://v4.apollo.vuejs.org/guide-composable/query.html#options;
 *
 * @example
 * const { result, loading, error } = useSessionQuery();
 */
export function useSessionQuery(options: VueApolloComposable.UseQueryOptions<SessionQuery, SessionQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<SessionQuery, SessionQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<SessionQuery, SessionQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<SessionQuery, SessionQueryVariables>(SessionDocument, {}, options);
}
export type SessionQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<SessionQuery, SessionQueryVariables>;