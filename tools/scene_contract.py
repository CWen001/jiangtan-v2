# /// script
# requires-python = ">=3.11"
# dependencies = ["pydantic==2.13.5"]
# ///
"""Scene design contract, schema export, and evidence-aware review gate."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
from typing import Annotated, Literal, get_args

from pydantic import AfterValidator, BaseModel, ConfigDict, Field, StringConstraints, model_validator

ROOT = Path(__file__).resolve().parents[1]
Id = Annotated[str, StringConstraints(pattern=r"^[a-z][a-z0-9_-]{0,63}$")]
Text = Annotated[str, StringConstraints(strip_whitespace=True, min_length=8, max_length=1000)]
Short = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=160)]
Digest = Annotated[str, StringConstraints(pattern=r"^[0-9a-f]{64}$")]
Positive = Annotated[float, Field(gt=0, allow_inf_nan=False)]
Dimension = Literal["experience", "space", "place", "visual", "interaction", "delivery"]


def local_path(value: str) -> str:
    p = PurePosixPath(value)
    if p.is_absolute() or ".." in p.parts or "\\" in value or ":" in value or str(p) == ".":
        raise ValueError("Use a project-relative file path without '..', URLs or backslashes")
    return value


LocalPath = Annotated[Short, AfterValidator(local_path)]


class Model(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class Intent(Model):
    title: Short
    scene_function: Literal["exploration", "tension", "conversation", "combat", "transition"]
    player_goal: Text
    emotional_arc: Text = Field(description="玩家进入、经过、离开时的感受变化，写明原因。")
    memorable_moment: Text
    entry_knowledge: Text
    exit_change: Text = Field(description="行动后玩家知道了什么、获得了什么或空间发生了什么改变。")
    target_duration_seconds: Annotated[int, Field(gt=0)]
    scope_limits: Annotated[list[Text], Field(min_length=1)]


class Zone(Model):
    id: Id
    everyday_use: Text = Field(description="这个地方由谁使用、做什么、为何这样组织。")
    size_m: Annotated[list[Positive], Field(min_length=3, max_length=3)]
    enclosure: Literal["open", "semi_open", "enclosed"]
    elevation_m: Annotated[float, Field(allow_inf_nan=False)]
    focal_element_id: Id
    quiet_area: Text = Field(description="明确保留哪部分低信息密度空间，支持注意力分配。")


class Connection(Model):
    id: Id
    from_zone: Id
    to_zone: Id
    bidirectional: bool
    passage: Text = Field(description="具体通行方式、宽高与可读线索。")
    gate_element_id: Id | None


class Space(Model):
    entry_zone: Id
    exit_zone: Id
    zones: Annotated[list[Zone], Field(min_length=1)]
    connections: list[Connection]
    route_reason: Text = Field(description="顺序、分支或回路为何服务本场景；直线路径也需解释。")


class Beat(Model):
    id: Id
    zone_id: Id
    element_ids: Annotated[list[Id], Field(min_length=1)]
    mechanism: Literal["reveal", "choice", "hypothesis", "tension", "interaction", "relief", "wayfinding"]
    perception: Text = Field(description="玩家在此时此处实际能看到/听到的内容。")
    question_or_pressure: Text
    action: Text
    consequence: Text
    failure_or_alternative: Text = Field(description="忽略线索、做错或采用另一方式会怎样；无分支也需写清。")


class Interaction(Model):
    cue: Text
    action: Text
    precondition: Text
    state_change: Text
    feedback: Text
    unavailable_response: Text


class Element(Model):
    id: Id
    zone_id: Id
    kind: Literal["architecture", "prop", "character", "graphic", "light"]
    roles: Annotated[list[Literal["navigation", "occlusion", "route", "interaction", "story", "atmosphere", "scale"]], Field(min_length=1)]
    placement: Text
    removal_effect: Text = Field(description="移走此物，路径、视线、行动或场所理解具体损失什么。")
    asset_ids: Annotated[list[Id], Field(min_length=1)]
    interaction: Interaction | None

    @model_validator(mode="after")
    def interaction_role(self):
        if ("interaction" in self.roles) != (self.interaction is not None):
            raise ValueError(f"{self.id}: interaction role and interaction contract must agree")
        return self


class Viewpoint(Model):
    id: Id
    zone_id: Id
    focal_element_id: Id
    occluder_ids: list[Id]
    composition: Text = Field(description="第一人称高度下的前中后景、视线与显露关系。")
    reveal_after_moving: Text


class Lighting(Model):
    focal_contrast: Text
    dark_area_readability: Text
    transition: Text


class Look(Model):
    profile: Literal["noir-comic-3d2d-v1"]
    palette: Annotated[list[Annotated[str, StringConstraints(pattern=r"^#[0-9A-Fa-f]{6}$")]], Field(min_length=3, max_length=8)]
    shape_and_ink: Text
    surface_hierarchy: Text = Field(description="重复表面、局部贴花和独特物件如何分配细节。")
    density_rhythm: Text
    lighting: Lighting
    viewpoints: Annotated[list[Viewpoint], Field(min_length=1)]


class SpriteSpec(Model):
    facing: Text
    directions: Annotated[int, Field(ge=1)]
    animation_scope: Text
    world_height_m: Positive
    grounding: Text
    alpha_and_occlusion: Text
    light_response: Text


class Asset(Model):
    id: Id
    representation: Literal["surface", "decal", "sprite", "mesh", "engine_geometry"]
    producer: Literal["builtin_imagegen", "blender_mcp", "godot", "licensed_external"]
    specification: Text
    path: LocalPath | None = Field(description="工程中的实际交付文件；设计阶段可为null。")
    source_record: LocalPath | None = Field(description="提示词、Blender脚本/MCP记录或授权记录。")
    sprite: SpriteSpec | None

    @model_validator(mode="after")
    def sprite_contract(self):
        if (self.representation == "sprite") != (self.sprite is not None):
            raise ValueError(f"{self.id}: sprite assets require SpriteSpec; other assets must use null")
        return self


class Production(Model):
    assets: Annotated[list[Asset], Field(min_length=1)]
    implementation_inputs: Annotated[list[LocalPath], Field(min_length=1)]
    target_machine: Text
    performance_target: Text = Field(description="目标设备、分辨率、最低可接受帧率/帧时间与测量方法。")
    validation_route: Text = Field(description="运行时走哪条路线、测试哪些遮挡/交互/返回状态。")


def indexed(items, label: str) -> dict:
    result = {item.id: item for item in items}
    if len(result) != len(items):
        raise ValueError(f"Duplicate {label} ids")
    return result


class SceneContract(Model):
    schema_version: Literal["0.1.0"]
    scene_id: Id
    revision: Annotated[int, Field(ge=1)]
    describes: Literal["proposal", "as_built"]
    intent: Intent
    space: Space
    beats: Annotated[list[Beat], Field(min_length=1)]
    elements: Annotated[list[Element], Field(min_length=1)]
    look: Look
    production: Production

    @model_validator(mode="after")
    def relationships(self):
        zones = indexed(self.space.zones, "zone")
        elements = indexed(self.elements, "element")
        assets = indexed(self.production.assets, "asset")
        indexed(self.space.connections, "connection")
        indexed(self.beats, "beat")
        indexed(self.look.viewpoints, "viewpoint")

        def ref(value, pool, context):
            if value not in pool:
                raise ValueError(f"{context}: unknown reference {value}")

        ref(self.space.entry_zone, zones, "entry")
        ref(self.space.exit_zone, zones, "exit")
        for zone in zones.values():
            ref(zone.focal_element_id, elements, zone.id)
        for element in elements.values():
            ref(element.zone_id, zones, element.id)
            for asset_id in element.asset_ids:
                ref(asset_id, assets, element.id)
            if element.kind == "character" and not any(assets[a].representation == "sprite" for a in element.asset_ids):
                raise ValueError(f"{element.id}: this style profile requires a sprite character asset")
        for beat in self.beats:
            ref(beat.zone_id, zones, beat.id)
            for element_id in beat.element_ids:
                ref(element_id, elements, beat.id)
        for frame in self.look.viewpoints:
            ref(frame.zone_id, zones, frame.id)
            for element_id in [frame.focal_element_id, *frame.occluder_ids]:
                ref(element_id, elements, frame.id)
        if {v.zone_id for v in self.look.viewpoints} != set(zones):
            raise ValueError("Every zone needs at least one first-person viewpoint")
        graph = {zone_id: set() for zone_id in zones}
        for link in self.space.connections:
            ref(link.from_zone, zones, link.id)
            ref(link.to_zone, zones, link.id)
            if link.from_zone == link.to_zone:
                raise ValueError(f"{link.id}: connection must link distinct zones")
            graph[link.from_zone].add(link.to_zone)
            if link.bidirectional:
                graph[link.to_zone].add(link.from_zone)
            if link.gate_element_id is not None:
                ref(link.gate_element_id, elements, link.id)
                if elements[link.gate_element_id].interaction is None:
                    raise ValueError(f"{link.id}: gate must have an interaction contract")
        reachable, todo = set(), [self.space.entry_zone]
        while todo:
            zone = todo.pop()
            if zone not in reachable:
                reachable.add(zone)
                todo.extend(graph[zone] - reachable)
        if reachable != set(zones):
            raise ValueError(f"Zones unreachable from entry: {sorted(set(zones) - reachable)}")
        # This is potential topology only. Locks, collision and conditions require playtesting.
        return self


class FileStamp(Model):
    path: LocalPath
    sha256: Digest


class Evidence(Model):
    id: Id
    kind: Literal["screenshot", "playthrough", "measurement", "source_inspection"]
    file: FileStamp
    locator: Text = Field(description="截图机位、视频时间段、日志行或源代码位置。")
    observation: Text = Field(description="观察到什么；不能把计划中的效果写成已观察结果。")


class Assessment(Model):
    dimension: Dimension
    verdict: Literal["pass", "fail", "unverified"]
    rationale: Text
    evidence_ids: list[Id]
    next_action: Text | None

    @model_validator(mode="after")
    def supported(self):
        if self.verdict in {"pass", "fail"} and not self.evidence_ids:
            raise ValueError("Pass/fail assessments require evidence")
        if self.verdict != "pass" and self.next_action is None:
            raise ValueError("Fail/unverified requires a concrete next action")
        return self


class SceneReview(Model):
    schema_version: Literal["0.1.0"]
    scene_id: Id
    revision: Annotated[int, Field(ge=1)]
    contract_sha256: Digest
    reviewer: Short
    reviewer_kind: Literal["human", "ai"]
    build_inputs: Annotated[list[FileStamp], Field(min_length=1)]
    evidence: Annotated[list[Evidence], Field(min_length=1)]
    assessments: Annotated[list[Assessment], Field(min_length=6, max_length=6)]

    @model_validator(mode="after")
    def coverage(self):
        evidence = indexed(self.evidence, "evidence")
        if {a.dimension for a in self.assessments} != set(get_args(Dimension)):
            raise ValueError("Assess all six dimensions exactly once")
        if len({f.path for f in self.build_inputs}) != len(self.build_inputs):
            raise ValueError("Duplicate build input paths")
        for assessment in self.assessments:
            if set(assessment.evidence_ids) - set(evidence):
                raise ValueError(f"{assessment.dimension}: unknown evidence ids")
        return self


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def resolve(root: Path, path: str) -> Path:
    resolved = (root / path).resolve()
    if not resolved.is_relative_to(root.resolve()):
        raise ValueError(f"Path escapes project root: {path}")
    return resolved


def required_inputs(contract: SceneContract) -> set[str]:
    paths = set(contract.production.implementation_inputs)
    for asset in contract.production.assets:
        paths.update(p for p in [asset.path, asset.source_record] if p is not None)
    return paths


def review_findings(contract: SceneContract, review: SceneReview, contract_path: Path, root: Path) -> list[str]:
    findings = []
    if contract.describes != "as_built":
        findings.append("A proposal cannot pass the delivery gate")
    if (review.scene_id, review.revision) != (contract.scene_id, contract.revision):
        findings.append("Review scene/revision mismatch")
    if review.contract_sha256 != digest(contract_path):
        findings.append("Contract changed after review")
    paths = {stamp.path for stamp in review.build_inputs}
    if paths != required_inputs(contract):
        findings.append("Build snapshot must cover exactly all implementation inputs, assets and source records")
    for asset in contract.production.assets:
        if asset.path is None:
            findings.append(f"{asset.id}: deliverable missing")
        if asset.producer != "godot" and asset.source_record is None:
            findings.append(f"{asset.id}: provenance record missing")
    for stamp in [*review.build_inputs, *(e.file for e in review.evidence)]:
        path = resolve(root, stamp.path)
        if not path.is_file():
            findings.append(f"Missing file: {stamp.path}")
        elif digest(path) != stamp.sha256:
            findings.append(f"Stale or modified file: {stamp.path}")
    evidence = {e.id: e for e in review.evidence}
    minimum = {
        "experience": {"playthrough"}, "space": {"screenshot", "playthrough"},
        "place": {"screenshot"}, "visual": {"screenshot"},
        "interaction": {"playthrough"}, "delivery": {"measurement", "playthrough"},
    }
    for assessment in review.assessments:
        if assessment.verdict != "pass":
            findings.append(f"{assessment.dimension}: {assessment.verdict} — {assessment.rationale}")
        else:
            kinds = {evidence[eid].kind for eid in assessment.evidence_ids}
            missing = minimum[assessment.dimension] - kinds
            if missing:
                findings.append(f"{assessment.dimension}: pass needs evidence types {sorted(missing)}")
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    export = commands.add_parser("export-schema")
    export.add_argument("--out", type=Path, default=ROOT / "design/schema")
    check = commands.add_parser("check")
    check.add_argument("contract", type=Path)
    check.add_argument("--review", type=Path)
    check.add_argument("--root", type=Path, default=ROOT)
    args = parser.parse_args()
    try:
        if args.command == "export-schema":
            args.out.mkdir(parents=True, exist_ok=True)
            for name, model in [("scene", SceneContract), ("review", SceneReview)]:
                schema = model.model_json_schema()
                schema["$schema"] = "https://json-schema.org/draft/2020-12/schema"
                (args.out / f"{name}.schema.json").write_text(json.dumps(schema, ensure_ascii=False, indent=2) + "\n")
            print("Exported structural schemas; cross-reference and evidence gates live in Python")
            return 0
        contract = SceneContract.model_validate_json(args.contract.read_text())
        if not args.review:
            print(json.dumps({"structure": "valid", "quality": "not_reviewed", "delivery_gate": "pending"}, ensure_ascii=False))
            return 0
        review = SceneReview.model_validate_json(args.review.read_text())
        findings = review_findings(contract, review, args.contract, args.root)
        print(json.dumps({"structure": "valid", "delivery_gate": "blocked" if findings else "review_record_complete",
                          "findings": findings, "notice": "Checks verify declarations and file integrity, not the truth of subjective judgments."}, ensure_ascii=False, indent=2))
        return 1 if findings else 0
    except (ValueError, OSError) as error:
        print(json.dumps({"structure": "invalid", "error": str(error)}, ensure_ascii=False, indent=2))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
