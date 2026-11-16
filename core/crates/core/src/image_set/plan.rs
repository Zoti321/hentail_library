use std::collections::{BTreeSet, HashMap, HashSet};

use crate::entity::{image_set_carriers, image_set_images, image_sets};

use super::discovery::{CarrierObs, LibraryObs, Listing, SetObs};
use super::dto::CarrierKind;
use super::ids::{image_set_id, image_set_image_id};

/// Catalog rows of one Image set library as last committed.
#[derive(Default)]
pub(crate) struct PriorCatalog {
    pub sets: Vec<image_sets::Model>,
    pub images: Vec<image_set_images::Model>,
    pub carriers: Vec<image_set_carriers::Model>,
}

/// Minimal diff against [PriorCatalog]; stable IDs keep unchanged rows untouched.
#[derive(Default)]
pub(crate) struct ImageSetPlan {
    pub sets_insert: Vec<image_sets::Model>,
    pub sets_delete: Vec<String>,
    /// Carrier paths whose row is deleted; changed carriers appear here and in `carriers_insert`.
    pub carriers_delete: Vec<String>,
    pub carriers_insert: Vec<image_set_carriers::Model>,
    pub images_insert: Vec<image_set_images::Model>,
    pub images_delete: Vec<String>,
    pub kept_count: usize,
    pub warnings: Vec<String>,
}

pub(crate) fn plan_image_set_sync(
    library_id: &str,
    obs: &LibraryObs,
    prior: &PriorCatalog,
) -> ImageSetPlan {
    let mut images_by_set: HashMap<&str, Vec<&image_set_images::Model>> = HashMap::new();
    for image in &prior.images {
        images_by_set
            .entry(image.image_set_id.as_str())
            .or_default()
            .push(image);
    }
    let mut carriers_by_set: HashMap<&str, Vec<&image_set_carriers::Model>> = HashMap::new();
    for carrier in &prior.carriers {
        carriers_by_set
            .entry(carrier.image_set_id.as_str())
            .or_default()
            .push(carrier);
    }
    let prior_set_by_rel: HashMap<&str, &image_sets::Model> = prior
        .sets
        .iter()
        .map(|set| (set.relative_path.as_str(), set))
        .collect();
    let obs_by_rel: HashMap<&str, &SetObs> = obs
        .sets
        .iter()
        .map(|set| (set.relative_path.as_str(), set))
        .collect();
    let rels: BTreeSet<&str> = prior_set_by_rel
        .keys()
        .chain(obs_by_rel.keys())
        .copied()
        .collect();

    let mut desired_sets = Vec::new();
    let mut desired_images = Vec::new();
    let mut desired_carriers = Vec::new();
    for rel in rels {
        let set_id = image_set_id(library_id, rel);
        let prior_images: &[&image_set_images::Model] = images_by_set
            .get(set_id.as_str())
            .map(Vec::as_slice)
            .unwrap_or(&[]);
        let prior_carriers: &[&image_set_carriers::Model] = carriers_by_set
            .get(set_id.as_str())
            .map(Vec::as_slice)
            .unwrap_or(&[]);
        let set_obs = obs_by_rel.get(rel).copied();
        let complete = set_obs.is_none_or(|set| set.complete);
        let mut images: Vec<image_set_images::Model> = Vec::new();
        let mut carriers: Vec<image_set_carriers::Model> = Vec::new();

        if let Some(set) = set_obs {
            for path in &set.loose {
                images.push(image_row(
                    library_id,
                    &set_id,
                    path,
                    "",
                    CarrierKind::Loose,
                    path,
                ));
            }
            if !complete {
                images.extend(
                    prior_images
                        .iter()
                        .filter(|image| image.carrier_kind == CarrierKind::Loose.as_str())
                        .map(|image| (*image).clone()),
                );
            }
            let mut observed: HashSet<&str> = HashSet::new();
            for carrier in &set.carriers {
                observed.insert(carrier.relative_path.as_str());
                match &carrier.listing {
                    Listing::Listed { stat, members } => {
                        carriers.push(carrier_row(library_id, &set_id, carrier, *stat));
                        for member in members {
                            images.push(image_row(
                                library_id,
                                &set_id,
                                &carrier.relative_path,
                                member,
                                carrier.kind,
                                member,
                            ));
                        }
                    }
                    Listing::Unchanged | Listing::Unlistable => {
                        keep_prior_carrier(
                            &carrier.relative_path,
                            prior_carriers,
                            prior_images,
                            &mut carriers,
                            &mut images,
                        );
                    }
                }
            }
            if !complete {
                for carrier in prior_carriers {
                    if !observed.contains(carrier.carrier_relative_path.as_str()) {
                        keep_prior_carrier(
                            &carrier.carrier_relative_path,
                            prior_carriers,
                            prior_images,
                            &mut carriers,
                            &mut images,
                        );
                    }
                }
            }
        }

        let mut seen = HashSet::new();
        images.retain(|image| seen.insert(image.image_set_image_id.clone()));
        let keep_set = !images.is_empty() || (!complete && prior_set_by_rel.contains_key(rel));
        if keep_set {
            desired_sets.push(image_sets::Model {
                image_set_id: set_id,
                library_id: library_id.to_string(),
                relative_path: rel.to_string(),
                name: rel.to_string(),
                is_root: rel.is_empty(),
            });
            desired_images.extend(images);
            desired_carriers.extend(carriers);
        }
    }

    diff(obs, prior, desired_sets, desired_images, desired_carriers)
}

fn diff(
    obs: &LibraryObs,
    prior: &PriorCatalog,
    desired_sets: Vec<image_sets::Model>,
    desired_images: Vec<image_set_images::Model>,
    desired_carriers: Vec<image_set_carriers::Model>,
) -> ImageSetPlan {
    let prior_set_ids: HashSet<&str> = prior.sets.iter().map(|s| s.image_set_id.as_str()).collect();
    let desired_set_ids: HashSet<&str> = desired_sets
        .iter()
        .map(|s| s.image_set_id.as_str())
        .collect();
    let prior_images: HashMap<&str, &image_set_images::Model> = prior
        .images
        .iter()
        .map(|i| (i.image_set_image_id.as_str(), i))
        .collect();
    let desired_image_ids: HashSet<&str> = desired_images
        .iter()
        .map(|i| i.image_set_image_id.as_str())
        .collect();
    let prior_carriers: HashMap<&str, &image_set_carriers::Model> = prior
        .carriers
        .iter()
        .map(|c| (c.carrier_relative_path.as_str(), c))
        .collect();
    let desired_carrier_paths: HashMap<&str, &image_set_carriers::Model> = desired_carriers
        .iter()
        .map(|c| (c.carrier_relative_path.as_str(), c))
        .collect();

    let carriers_delete = prior
        .carriers
        .iter()
        .filter(|c| {
            desired_carrier_paths
                .get(c.carrier_relative_path.as_str())
                .is_none_or(|d| *d != *c)
        })
        .map(|c| c.carrier_relative_path.clone())
        .collect();
    let carriers_insert = desired_carriers
        .iter()
        .filter(|c| {
            prior_carriers
                .get(c.carrier_relative_path.as_str())
                .is_none_or(|p| *p != *c)
        })
        .cloned()
        .collect();

    ImageSetPlan {
        sets_insert: desired_sets
            .iter()
            .filter(|s| !prior_set_ids.contains(s.image_set_id.as_str()))
            .cloned()
            .collect(),
        sets_delete: prior
            .sets
            .iter()
            .filter(|s| !desired_set_ids.contains(s.image_set_id.as_str()))
            .map(|s| s.image_set_id.clone())
            .collect(),
        carriers_delete,
        carriers_insert,
        images_insert: desired_images
            .iter()
            .filter(|i| !prior_images.contains_key(i.image_set_image_id.as_str()))
            .cloned()
            .collect(),
        images_delete: prior
            .images
            .iter()
            .filter(|i| !desired_image_ids.contains(i.image_set_image_id.as_str()))
            .map(|i| i.image_set_image_id.clone())
            .collect(),
        kept_count: desired_images
            .iter()
            .filter(|i| prior_images.contains_key(i.image_set_image_id.as_str()))
            .count(),
        warnings: obs.warnings.clone(),
    }
}

fn keep_prior_carrier(
    carrier_path: &str,
    prior_carriers: &[&image_set_carriers::Model],
    prior_images: &[&image_set_images::Model],
    carriers: &mut Vec<image_set_carriers::Model>,
    images: &mut Vec<image_set_images::Model>,
) {
    carriers.extend(
        prior_carriers
            .iter()
            .filter(|c| c.carrier_relative_path == carrier_path)
            .map(|c| (*c).clone()),
    );
    images.extend(
        prior_images
            .iter()
            .filter(|i| i.carrier_relative_path == carrier_path)
            .map(|i| (*i).clone()),
    );
}

fn carrier_row(
    library_id: &str,
    set_id: &str,
    carrier: &CarrierObs,
    stat: (i64, i64),
) -> image_set_carriers::Model {
    image_set_carriers::Model {
        library_id: library_id.to_string(),
        carrier_relative_path: carrier.relative_path.clone(),
        image_set_id: set_id.to_string(),
        carrier_kind: carrier.kind.as_str().to_string(),
        observed_size: stat.0,
        observed_modified_ms: stat.1,
    }
}

fn image_row(
    library_id: &str,
    set_id: &str,
    carrier_path: &str,
    member_path: &str,
    kind: CarrierKind,
    name_source: &str,
) -> image_set_images::Model {
    let name = name_source.rsplit('/').next().unwrap_or(name_source);
    image_set_images::Model {
        image_set_image_id: image_set_image_id(library_id, carrier_path, member_path),
        library_id: library_id.to_string(),
        image_set_id: set_id.to_string(),
        carrier_relative_path: carrier_path.to_string(),
        member_path: member_path.to_string(),
        carrier_kind: kind.as_str().to_string(),
        name: name.to_string(),
    }
}
