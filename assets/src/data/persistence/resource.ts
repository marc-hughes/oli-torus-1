import * as Immutable from 'immutable';
import { ProjectSlug, ResourceSlug, ObjectiveSlug } from 'data/types';
import { makeRequest } from './common';
import { ResourceContent } from '../content/resource';

export type ResourceUpdate = {
  title: string,
  objectives: Immutable.List<ObjectiveSlug>,
  content: Immutable.List<ResourceContent>,
};

export type Edited = { type: 'success', revisionSlug: string };

export function edit(
  project: ProjectSlug,
  resource: ResourceSlug,
  update: ResourceUpdate) {

  const params = {
    method: 'PUT',
    body: JSON.stringify({ update }),
    url: `/project/${project}/resource/${resource}`,
  };

  return makeRequest<Edited>(params);
}
